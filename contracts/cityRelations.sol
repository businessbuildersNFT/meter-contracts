// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ECityRelations.sol";
import "./interfaces/ETeamLeaderValidations.sol";
import "./interfaces/EUniversitiesStorage.sol";
import "./interfaces/ECityStorage.sol";
import "./interfaces/EBBERC721.sol";
import "./cityRelationsGetters.sol";
import "./factory.sol";
import "./cities.sol";

contract CityRelations is ECityRelations {
    mapping(uint256 => uint256) private factoryGame; // Factory => Time
    mapping(address => uint256) private removePenal; // Factory => Address => Time

    IERC20 private token;
    Cities private cities;
    Factories private factories;
    BBERC721 private employees;
    BBERC721 private miniEmployees;
    BBERC721 private multiEmployees;
    ETeamLeaderValidations private teamLeader;
    ECityRelationsStorage private citiesStorage;
    ECityUniversitiesStorage private citiesUniversities;
    CityRelationsGetters private cityGetters;

    function initialize(
        address _token,
        address _employees,
        address _miniEmployees,
        address _multiEmployees,
        address _factories,
        address _cities,
        address _citiesStorage,
        address _citiesUniversities,
        address _cityGetters,
        address _teamLeader
    ) external initializer {
        _setupRole(MAIN_OWNER, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        creator = _msgSender();
        employees = BBERC721(_employees);
        miniEmployees = BBERC721(_miniEmployees);
        multiEmployees = BBERC721(_multiEmployees);
        factories = Factories(_factories);
        cities = Cities(_cities);
        token = IERC20(_token);
        cityGetters = CityRelationsGetters(_cityGetters);
        citiesStorage = ECityRelationsStorage(_citiesStorage);
        citiesUniversities = ECityUniversitiesStorage(_citiesUniversities);
        teamLeader = ETeamLeaderValidations(_teamLeader);
    }

    function changeAddresses(
        address _token,
        address _employees,
        address _miniEmployees,
        address _multiEmployees,
        address _factories,
        address _cities,
        address _citiesStorage,
        address _citiesUniversities,
        address _cityGetters,
        address _teamLeader
    ) external onlyRole(MAIN_OWNER) {
        employees = BBERC721(_employees);
        miniEmployees = BBERC721(_miniEmployees);
        multiEmployees = BBERC721(_multiEmployees);
        factories = Factories(_factories);
        cities = Cities(_cities);
        token = IERC20(_token);
        cityGetters = CityRelationsGetters(_cityGetters);
        citiesStorage = ECityRelationsStorage(_citiesStorage);
        citiesUniversities = ECityUniversitiesStorage(_citiesUniversities);
        teamLeader = ETeamLeaderValidations(_teamLeader);
    }

    function updateRedirectAddress(address _c, address _p)
        external
        onlyRole(MAIN_OWNER)
    {
        creator = _c;
        playToEarn = _p;
    }

    function updateResetedTime() external onlyRole(MAIN_OWNER) {
        resetedTime = block.timestamp;
    }

    function gameData() external view returns (CitiesLibrary.GameData memory) {
        return
            CitiesLibrary.GameData(
                cityGetters.creatorFees(),
                cityGetters.cityFees(),
                cityGetters.factoryFees(),
                cityGetters.playToEarnFees(),
                citiesStorage.getRelationsData()
            );
    }

    function changePropertyState(
        uint256 _c,
        uint256 _x,
        uint256 _y,
        bool _s
    ) external {
        require(cities.ownerOf(_c) == _msgSender(), INVALID_OWNER);
        citiesStorage.changePropertyState(_c, _x, _y, _s);
        emit ChangePropertyState(_c, _x, _y);
    }

    function createCityRelation(
        uint256 _c,
        uint256 _f,
        uint256 _x,
        uint256 _y
    ) external {
        require(factories.ownerOf(_f) == _msgSender(), INVALID_OWNER);

        require(
            cities.getLands(_c) >= citiesStorage.getTotalCityRelations(_c),
            INVALID_CITY_SPACES
        );

        require(!citiesStorage.getRelationState(_c, _f), INVALID_RELATION);
        require(!citiesStorage.getFactoryState(_f), INVALID_FACTORY_STATE);

        CitiesLibrary.PropertyState memory property = citiesStorage
            .getPropertyData(_c, _x, _y);

        require(
            cities.ownerOf(_c) == _msgSender() || property.state == true,
            INVALID_PROPERTY_STATE
        );

        require(property.hasRelation == false, HAS_RELATION);
        require(canFactoryPlay(_f), INVALID_FACTORY_STATE);

        CitiesLibrary.CityRelationProperties memory _props = cityGetters
            .getCityRelationProperties(_c, _f, _msgSender());

        if (_props.creationPrice > 0) {
            token.transferFrom(_msgSender(), playToEarn, _props.creationPrice);
        }

        citiesStorage.addCityRelation(_c, _f, _x, _y, _props.maxFactoryPoints);
        teamLeader.addXPToOwner(_msgSender(), 10);
        factoryGame[_f] = block.timestamp;

        if (_props.baseMultiplier > 0) {
            citiesStorage.updateRelation(
                _c,
                _f,
                citiesStorage.initialBackruptcy(),
                citiesStorage.entryPrice(),
                0,
                _props.multiplier
            );
        }

        emit CityRelation(
            CityRelationEvent(
                _c,
                _f,
                _msgSender(),
                _x,
                _y,
                _props.creationPrice,
                _props.maxFactoryPoints,
                _props.maxMultiplier,
                block.timestamp
            )
        );
    }

    function removeCityRelation(
        uint256 _c,
        uint256 _f,
        uint256 _x,
        uint256 _y
    ) external {
        require(cities.validate(_c), INVALID_CITY);
        require(factories.validate(_f), INVALID_FACTORY);
        require(citiesStorage.getFactoryState(_f), INVALID_FACTORY_STATE);
        require(factories.ownerOf(_f) == _msgSender(), INVALID_OWNER);
        require(canRemoveTheRelation(_c, _f), INVALID_RELATION_STATE);
        require(citiesStorage.getRelationState(_c, _f), INVALID_RELATION);

        require(
            citiesStorage.getPropertyData(_c, _x, _y).hasRelation == true,
            INVALID_RELATION
        );

        teamLeader.addXPToOwner(_msgSender(), 1);

        hardCityRelationEnd(_c, _f, factories.ownerOf(_f));
    }

    function createFactoryRelation(
        uint256 _c,
        uint256 _f,
        uint256[] calldata _e,
        uint256[] calldata _m
    ) external {
        require(address(playToEarn) != address(0), INVALID_ADDRESS);
        require(address(creator) != address(0), INVALID_ADDRESS);
        require(canCreateARelation(_msgSender()), INVALID_ADDITION);
        require(_e.length > 0 || _m.length > 0, INVALID_EMPLOYEES);
        require(citiesStorage.getFactoryState(_f), INVALID_FACTORY_STATE);
        require(citiesStorage.getRelationState(_c, _f), INVALID_RELATION);

        require(
            !citiesStorage.getFactoryAdditionState(_f, _msgSender()),
            INVALID_ADDITION
        );

        require(cities.validate(_c), INVALID_CITY);
        require(factories.validate(_f), INVALID_FACTORY);

        CitiesLibrary.NextProperties memory _p = CitiesLibrary.NextProperties(
            factories.getType(_f),
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );

        if (_e.length > 0) {
            CitiesLibrary.EmployeesData memory eData = extractEmployees(
                _e,
                _msgSender(),
                _p.factoryType,
                false
            );

            _p.sameTypes += eData.sameTypes;
            _p.employeesPoints += eData.points;
        }

        if (_m.length > 0) {
            CitiesLibrary.EmployeesData memory meData = extractMulti(
                _m,
                _msgSender(),
                _p.factoryType,
                false
            );

            _p.sameTypes += meData.sameTypes;
            _p.employeesPoints += meData.points;
        }

        CitiesLibrary.CityRelation memory _r = citiesStorage.getRelationData(
            _c,
            _f
        );

        _p.totalPoints = _r.playedPoints + _p.employeesPoints;
        _p.entryCost = _p.employeesPoints * _r.momentPrice;
        _p.totalEmployees = _e.length + _m.length;
        _p.nextMultiplicator = _r.multiplicator;
        _p.relationPercentage =
            (_p.sameTypes * 100) /
            ((_p.totalEmployees) * 4);

        if (_p.totalPoints >= _r.maxFactoryPoints) {
            _p.totalPoints = _r.maxFactoryPoints;
        }

        uint256 _maxMultiplicator = teamLeader.getMaxMultiplicator(
            factories.ownerOf(_f)
        );

        if (
            _p.employeesPoints >= citiesStorage.relevantPoints() &&
            _r.multiplicator < citiesStorage.maxFactoryMultiplicator() &&
            _p.nextMultiplicator < _maxMultiplicator
        ) _p.nextMultiplicator++;

        citiesStorage.addFactoryAddition(
            _p.relationPercentage,
            _f,
            _p.totalEmployees,
            _p.entryCost,
            _p.employeesPoints,
            _msgSender()
        );

        citiesStorage.updateRelation(
            _c,
            _f,
            cityGetters.calcBankrupt(_p.totalPoints, _r.maxFactoryPoints),
            cityGetters.calcNextPrice(_r.momentPrice, _r.augment),
            _p.totalPoints,
            _p.nextMultiplicator
        );

        if (_p.totalPoints == _r.maxFactoryPoints) {
            softCityRelationEnd(
                _c,
                _f,
                (_p.entryCost * cityGetters.factoryFees()) / 100,
                0
            );

            teamLeader.addXPToOwner(_msgSender(), _p.totalEmployees + 10);
        } else {
            citiesStorage.addFactoryRewards(
                _f,
                (_p.entryCost * cityGetters.factoryFees()) / 100
            );

            teamLeader.addXPToOwner(_msgSender(), _p.totalEmployees);
        }

        citiesStorage.addCityRewards(
            _c,
            (_p.entryCost * cityGetters.cityFees()) / 100
        );

        token.transferFrom(
            _msgSender(),
            playToEarn,
            (_p.entryCost * cityGetters.playToEarnFees()) / 100
        );

        emit FactoryAddition(
            FactoryAdditionEvent(
                _c,
                _f,
                _msgSender(),
                _p.relationPercentage,
                _p.totalEmployees,
                _p.entryCost,
                _p.employeesPoints,
                _maxMultiplicator,
                block.timestamp
            )
        );
    }

    function removeFactoryRelation(uint256 _c, uint256 _f) external {
        require(address(playToEarn) != address(0), INVALID_ADDRESS);
        require(address(creator) != address(0), INVALID_ADDRESS);
        require(citiesStorage.getFactoryState(_f), INVALID_FACTORY_STATE);
        require(citiesStorage.getRelationState(_c, _f), INVALID_RELATION);
        require(cities.validate(_c), INVALID_CITY);
        require(factories.validate(_f), INVALID_FACTORY);

        CitiesLibrary.FactoryAddition memory _addition = citiesStorage
            .getFactoryAddition(_f, _msgSender());

        CitiesLibrary.CityRelation memory _relation = citiesStorage
            .getRelationData(_c, _f);

        require(
            _addition.active && _addition.agregator == _msgSender(),
            INVALID_ADDITION
        );

        citiesStorage.removeFactoryAddition(_f, _msgSender());

        uint256 _totalPoints = _relation.playedPoints -
            _addition.relationPoints;

        uint256 _nextMultiplicator = _relation.multiplicator;

        uint256 _rewards = cityGetters.getOwnerRelationRewards(
            _c,
            _f,
            _msgSender()
        );

        if (
            _relation.multiplicator > 0 &&
            _addition.relationPoints >= citiesStorage.relevantPoints()
        ) _nextMultiplicator--;

        citiesStorage.updateRelation(
            _c,
            _f,
            cityGetters.calcBankrupt(_totalPoints, _relation.maxFactoryPoints),
            _relation.momentPrice,
            _totalPoints,
            _nextMultiplicator
        );

        citiesUniversities.addRelationRewards(_msgSender(), _rewards);
        removePenal[_msgSender()] = block.timestamp + cityGetters.removeTime();
        teamLeader.addXPToOwner(_msgSender(), 1);

        emit RemoveFactoryAddition(
            RemoveFactoryAdditionEvent(
                _c,
                _f,
                _msgSender(),
                _rewards,
                _relation.multiplicator,
                block.timestamp
            )
        );
    }

    function softCityRelationEnd(
        uint256 _c,
        uint256 _f,
        uint256 _a,
        uint256 _h
    ) private {
        CitiesLibrary.CityRelation memory _relation = citiesStorage
            .getRelationData(_c, _f);

        address[] memory _fa = citiesStorage.getFactoryAdditions(_f);
        uint256 _fr = citiesStorage.getFactoryRewards(_f);

        for (uint256 i = 0; i < _fa.length; i++) {
            uint256 _rewards = cityGetters.getOwnerRelationRewards(
                _c,
                _f,
                _fa[i]
            );

            citiesUniversities.addRelationRewards(_fa[i], _rewards);
            citiesStorage.removeFactoryAddition(_f, _fa[i]);

            emit RemoveFactoryAddition(
                RemoveFactoryAdditionEvent(
                    _c,
                    _f,
                    _fa[i],
                    _rewards,
                    teamLeader.getMaxMultiplicator(_msgSender()),
                    block.timestamp
                )
            );
        }

        citiesStorage.removeFactoryRewards(_f, _fr);
        citiesStorage.removeCityRelation(_c, _f, _relation.x, _relation.y);
        citiesUniversities.addFactoriesRewards(factories.ownerOf(_f), _fr + _a);

        emit RemoveCityRelation(
            RemoveCityRelationEvent(
                _c,
                _f,
                factories.ownerOf(_f),
                _relation.x,
                _relation.y,
                _relation.multiplicator,
                _fr + _a,
                _h,
                block.timestamp
            )
        );
    }

    function hardCityRelationEnd(
        uint256 _c,
        uint256 _f,
        address _o
    ) private {
        uint256 _hardRelationPayment = cityGetters.getHardEndPrice(_c, _f);

        if (_hardRelationPayment > 0) {
            token.transferFrom(_o, playToEarn, _hardRelationPayment);
        }

        softCityRelationEnd(_c, _f, 0, _hardRelationPayment);
    }

    // Alterators

    function extractEmployees(
        uint256[] calldata _e,
        address _o,
        uint8 _t,
        bool _r
    ) private returns (CitiesLibrary.EmployeesData memory) {
        uint256 _p = 0;
        uint256 _s = 0;

        for (uint256 i = 0; i < _e.length; i++) {
            require(employees.ownerOf(_e[i]) == _o, INVALID_OWNER);
            uint8[4] memory parts = employees.getParts(_e[i]);
            _p += employees.getPoints(_e[i]);
            for (uint256 j = 0; j < parts.length; j++) {
                if (parts[j] == _t) _s++;
            }

            if (!_r) {
                require(citiesStorage.canEmployeePlay(_e[i]), INVALID_EMPLOYEE);
                citiesStorage.playWithEmployee(_e[i]);
            }
        }

        return CitiesLibrary.EmployeesData(_p, _s);
    }

    function extractMulti(
        uint256[] calldata _e,
        address _o,
        uint8 _t,
        bool _r
    ) private returns (CitiesLibrary.EmployeesData memory) {
        uint256 _p = 0;
        uint256 _s = 0;

        for (uint256 i = 0; i < _e.length; i++) {
            require(multiEmployees.ownerOf(_e[i]) == _o, INVALID_OWNER);
            if (multiEmployees.getType(_e[i]) == _t) {
                _s += 4;
            }
            _p += multiEmployees.getPoints(_e[i]);

            if (!_r) {
                require(
                    citiesStorage.canMultiEmployeePlay(_e[i]),
                    INVALID_EMPLOYEE
                );
                citiesStorage.playWithMultiEmployee(_e[i]);
            }
        }

        return CitiesLibrary.EmployeesData(_p, _s);
    }

    //Validations

    function canRemoveTheRelation(uint256 _c, uint256 _f)
        public
        view
        returns (bool)
    {
        return
            citiesStorage.getTotalFactoryAdditions(_f) == 0 ||
            (cityGetters.getRemoveRelationTime(_c, _f) <= block.timestamp);
    }

    function canCreateARelation(address _c) public view returns (bool) {
        return block.timestamp > removePenal[_c];
    }

    function canFactoryPlay(uint256 _f) public view returns (bool) {
        return factoryGame[_f] < resetedTime;
    }
}
