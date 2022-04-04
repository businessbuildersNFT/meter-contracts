// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/cities.sol";
import "./factory.sol";
import "./cities.sol";
import "./employee.sol";
import "./miniEmployee.sol";
import "./multiEmployee.sol";
import "./cityRelationsStorage.sol";
import "./interfaces/EUniversitiesStorage.sol";

contract CityRelations is Initializable, Context, AccessControl {
    event CityRelation(
        uint256 indexed city,
        uint256 indexed factory,
        address indexed agregator,
        uint256 x,
        uint256 y,
        uint256 payment,
        uint256 maxFactoryPoints,
        uint256 time
    );

    event RemoveCityRelation(
        uint256 indexed city,
        uint256 indexed factory,
        address indexed agregator,
        uint256 x,
        uint256 y,
        uint256 rewards,
        uint256 hardPayment,
        uint256 time
    );

    event FactoryAddition(
        uint256 indexed city,
        uint256 indexed factory,
        uint256 relationPercentage,
        uint256 totalEmployees,
        uint256 entryPayment,
        uint256 relationPoints,
        address indexed agregator,
        uint256 time
    );

    event RemoveFactoryAddition(
        uint256 indexed city,
        uint256 indexed factory,
        address indexed agregator,
        uint256 rewards,
        uint256 time
    );

    event ChangePropertyState(uint256 city, uint256 x, uint256 y);

    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_CITY_SPACES = "CR: Not enought spaces";
    string public constant INVALID_PROPERTY_STATE = "CR: Invalid property";
    string public constant HAS_RELATION = "CR: The property has a relation";
    string public constant INVALID_OWNER = "CR: Invalid owner";
    string public constant INVALID_FACTORY_STATE = "CR: Invalid factory";
    string public constant INVALID_RELATION_POINTS = "CR: Invalid points";
    string public constant INVALID_PAYMENT = "CR: Invalid payment";
    string public constant INVALID_EMPLOYEES = "CR: Invalid employees";
    string public constant INVALID_CITY = "CR: Invalid city";
    string public constant INVALID_FACTORY = "CR: Invalid factory";
    string public constant INVALID_RELATION = "CR: Invalid relation";
    string public constant INVALID_RELATION_STATE = "CR: Invalid state";
    string public constant INVALID_ADDRESS = "CR: Invalid address";
    string public constant INVALID_ADDITION = "CR: Invalid addition";
    string public constant INVALID_EMPLOYEE = "CR: Invalid employee";

    mapping(uint256 => uint256) private factoryGame; // Factory => Time
    mapping(address => uint256) private removePenal; // Factory => Address => Time

    Factories private factories;
    Cities private cities;
    Employees private employees;
    MiniEmployees private miniEmployees;
    MultiEmployees private multiEmployees;
    IERC20 private token;
    CityRelationsStorage private citiesStorage;
    ECityUniversitiesStorage private citiesUniversities;

    uint8 private creatorFees = 0;
    uint8 private cityFees = 5;
    uint8 private factoryFees = 10;
    uint8 private playToEarnFees = 100;
    uint8 public rewardsMultiplier = 5;
    uint8 public createRelationBase = 2;
    uint16 public errorRange = 20;
    uint32 public removeTime = 86400;
    uint256 public resetedTime;

    address private creator;
    address private playToEarn;

    function initialize(
        IERC20 _token,
        Employees _employees,
        MiniEmployees _miniEmployees,
        MultiEmployees _multiEmployees,
        Factories _factories,
        Cities _cities,
        CityRelationsStorage _citiesStorage,
        ECityUniversitiesStorage _citiesUniversities
    ) external initializer {
        _setupRole(MAIN_OWNER, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        creator = _msgSender();
        employees = _employees;
        miniEmployees = _miniEmployees;
        multiEmployees = _multiEmployees;
        factories = _factories;
        cities = _cities;
        token = _token;
        citiesStorage = _citiesStorage;
        citiesUniversities = _citiesUniversities;
    }

    //Update

    function updateFees(
        uint8 _creator,
        uint8 _city,
        uint8 _factory,
        uint8 _playToEarn
    ) external onlyRole(MAIN_OWNER) {
        creatorFees = _creator;
        cityFees = _city;
        factoryFees = _factory;
        playToEarnFees = _playToEarn;
    }

    function updateResetedTime() external onlyRole(MAIN_OWNER) {
        resetedTime = block.timestamp;
    }

    function updateRedirectAddress(address _creator, address _playToEarn)
        external
        onlyRole(MAIN_OWNER)
    {
        creator = _creator;
        playToEarn = _playToEarn;
    }

    function updatePenalTime(uint32 _time) external onlyRole(MAIN_OWNER) {
        removeTime = _time;
    }

    function updateErrorRange(uint16 _range) external onlyRole(MAIN_OWNER) {
        errorRange = _range;
    }

    function updateRewardsMultiplier(uint8 _total)
        external
        onlyRole(MAIN_OWNER)
    {
        rewardsMultiplier = _total;
    }

    // Getters

    function gameData() external view returns (CitiesLibrary.GameData memory) {
        return
            CitiesLibrary.GameData(
                creatorFees,
                cityFees,
                factoryFees,
                playToEarnFees,
                citiesStorage.getRelationsData()
            );
    }

    function getOwnerRelationRewards(
        uint256 _city,
        uint256 _factory,
        address _owner
    ) public view returns (uint256) {
        CitiesLibrary.FactoryAddition memory _addition = citiesStorage
            .getFactoryAddition(_factory, _owner);

        uint256 _rewards = getOwnerTemporalRewards(_city, _factory, _owner) +
            _addition.entryPayment;

        return _rewards + ((_rewards * rewardsMultiplier) / 100);
    }

    function getOwnerTemporalRewards(
        uint256 _city,
        uint256 _factory,
        address _owner
    ) private view returns (uint256) {
        CitiesLibrary.CityRelation memory _relation = citiesStorage
            .getRelationData(_city, _factory);

        CitiesLibrary.FactoryAddition memory _addition = citiesStorage
            .getFactoryAddition(_factory, _owner);

        return
            relationRewards(
                _relation.multiplicator +
                    calcAddition(
                        _addition.totalEmployees,
                        citiesStorage.augmentEmployees(),
                        citiesStorage.maxEmployeeMultiplicator()
                    ),
                _addition.relationPoints + factories.getMultiplier(_factory),
                _addition.relationPercentage
            );
    }

    function getRemoveRelationTime(uint256 _city, uint256 _factory)
        public
        view
        returns (uint256)
    {
        return
            citiesStorage.getRelationStartTime(_city, _factory) +
            citiesStorage.minTime();
    }

    function canFactoryPlay(uint256 _factory) public view returns (bool) {
        return factoryGame[_factory] < resetedTime;
    }

    function getHardEndPrice(uint256 _city, uint256 _factory)
        public
        view
        returns (uint256)
    {
        CitiesLibrary.CityRelation memory _relation = citiesStorage
            .getRelationData(_city, _factory);

        return
            calculateHardEnd(
                _relation.maxFactoryPoints,
                _relation.momentPrice,
                _relation.banckruptcyProbability
            );
    }

    function canCreateARelation(address _creator) public view returns (bool) {
        return block.timestamp > removePenal[_creator];
    }

    // Relations

    function changePropertyState(
        uint256 _city,
        uint256 _x,
        uint256 _y,
        bool _state
    ) external {
        require(cities.ownerOf(_city) == _msgSender(), INVALID_OWNER);
        citiesStorage.changePropertyState(_city, _x, _y, _state);
        emit ChangePropertyState(_city, _x, _y);
    }

    function createCityRelation(
        uint256 _city,
        uint256 _factory,
        uint256 _x,
        uint256 _y
    ) external {
        require(address(playToEarn) != address(0), INVALID_ADDRESS);

        require(
            cities.getLands(_city) > citiesStorage.getTotalCityRelations(_city),
            INVALID_CITY_SPACES
        );

        require(
            !citiesStorage.getRelationState(_city, _factory),
            INVALID_RELATION
        );

        require(
            !citiesStorage.getFactoryState(_factory),
            INVALID_FACTORY_STATE
        );

        require(factories.ownerOf(_factory) == _msgSender(), INVALID_OWNER);

        CitiesLibrary.PropertyState memory property = citiesStorage
            .getPropertyData(_city, _x, _y);

        require(
            cities.ownerOf(_city) == _msgSender() || property.state == true,
            INVALID_PROPERTY_STATE
        );

        require(property.hasRelation == false, HAS_RELATION);

        require(factoryGame[_factory] < resetedTime, INVALID_FACTORY_STATE);

        uint256 _maxFactoryPoints = citiesStorage.relationFactoryBase() *
            factories.getMultiplier(_factory);

        uint256 _creationPrice = calcRelation(
            citiesStorage.entryPrice(),
            _maxFactoryPoints,
            createRelationBase
        );

        require(
            token.transferFrom(_msgSender(), playToEarn, _creationPrice),
            INVALID_PAYMENT
        );

        citiesStorage.addCityRelation(
            _city,
            _factory,
            _x,
            _y,
            _maxFactoryPoints
        );

        uint256 _baseMultiplier = citiesUniversities.getBaseCityMultiplier(
            _city
        );

        if (_baseMultiplier > 0) {
            citiesStorage.updateRelation(
                _city,
                _factory,
                citiesStorage.initialBackruptcy(),
                citiesStorage.entryPrice(),
                0,
                _baseMultiplier
            );
        }

        factoryGame[_factory] = block.timestamp;

        emit CityRelation(
            _city,
            _factory,
            _msgSender(),
            _x,
            _y,
            _creationPrice,
            _maxFactoryPoints,
            block.timestamp
        );
    }

    function removeCityRelation(
        uint256 _city,
        uint256 _factory,
        uint256 _x,
        uint256 _y
    ) external {
        require(cities.validate(_city), INVALID_CITY);
        require(factories.validate(_factory), INVALID_FACTORY);
        require(citiesStorage.getFactoryState(_factory), INVALID_FACTORY_STATE);
        require(factories.ownerOf(_factory) == _msgSender(), INVALID_OWNER);

        require(canRemoveTheRelation(_city, _factory), INVALID_RELATION);

        require(
            citiesStorage.getRelationState(_city, _factory),
            INVALID_RELATION
        );

        require(
            citiesStorage.getPropertyData(_city, _x, _y).hasRelation == true,
            INVALID_RELATION
        );

        require(canRemoveTheRelation(_city, _factory), INVALID_RELATION_STATE);

        hardCityRelationEnd(_city, _factory, factories.ownerOf(_factory));
    }

    function createFactoryRelation(
        uint256 _city,
        uint256 _factory,
        uint256[] memory _employees,
        uint256[] memory _multiEmployees
    ) external {
        require(canCreateARelation(_msgSender()), INVALID_ADDITION);
        require(address(playToEarn) != address(0), INVALID_ADDRESS);
        require(address(creator) != address(0), INVALID_ADDRESS);

        require(
            _employees.length > 0 || _multiEmployees.length > 0,
            INVALID_EMPLOYEES
        );

        require(citiesStorage.getFactoryState(_factory), INVALID_FACTORY_STATE);

        require(
            citiesStorage.getRelationState(_city, _factory),
            INVALID_RELATION
        );

        require(
            !citiesStorage.getFactoryAdditionState(_factory, _msgSender()),
            INVALID_ADDITION
        );

        require(cities.validate(_city), INVALID_CITY);
        require(factories.validate(_factory), INVALID_FACTORY);

        uint256 _employeesPoints = 0;
        uint256 _sameTypes = 0;
        uint8 _factoryType = factories.getType(_factory);

        if (_employees.length > 0) {
            CitiesLibrary.EmployeesData
                memory employeesData = extractAllEmployeesPoints(
                    _employees,
                    _msgSender(),
                    _factoryType,
                    false
                );

            _sameTypes += employeesData.sameTypes;
            _employeesPoints += employeesData.points;
        }

        if (_multiEmployees.length > 0) {
            CitiesLibrary.EmployeesData
                memory multiEmployeesData = extractAllMultiEmployeesPoints(
                    _multiEmployees,
                    _msgSender(),
                    _factoryType,
                    false
                );

            _sameTypes += multiEmployeesData.sameTypes;
            _employeesPoints += multiEmployeesData.points;
        }

        CitiesLibrary.CityRelation memory relation = citiesStorage
            .getRelationData(_city, _factory);

        uint256 _totalPoints = relation.playedPoints + _employeesPoints;

        if (_totalPoints > relation.maxFactoryPoints) {
            _totalPoints = relation.maxFactoryPoints;
        }

        uint256 _entryCost = _employeesPoints * relation.momentPrice;
        uint256 _totalEmployees = _employees.length + _multiEmployees.length;
        uint256 _nextMultiplicator = relation.multiplicator;

        uint256 _relationPercentage = (_sameTypes * 100) /
            ((_totalEmployees) * 4);

        if (
            _employeesPoints >= citiesStorage.relevantPoints() &&
            relation.multiplicator < citiesStorage.maxFactoryMultiplicator()
        ) {
            _nextMultiplicator++;
        }

        citiesStorage.addFactoryAddition(
            _relationPercentage,
            _factory,
            _totalEmployees,
            _entryCost,
            _employeesPoints,
            _msgSender()
        );

        citiesStorage.updateRelation(
            _city,
            _factory,
            calcBankrupt(_totalPoints, relation.maxFactoryPoints),
            calcNextPrice(relation.momentPrice, relation.augment),
            _totalPoints,
            _nextMultiplicator
        );

        if (_totalPoints == relation.maxFactoryPoints) {
            softCityRelationEnd(
                _city,
                _factory,
                (_entryCost * factoryFees) / 100,
                0
            );
        } else {
            citiesStorage.addFactoryRewards(
                _factory,
                (_entryCost * factoryFees) / 100
            );
        }

        citiesStorage.addCityRewards(_city, (_entryCost * cityFees) / 100);

        if (playToEarnFees > 0) {
            require(
                token.transferFrom(
                    _msgSender(),
                    playToEarn,
                    (_entryCost * playToEarnFees) / 100
                )
            );
        }

        emit FactoryAddition(
            _city,
            _factory,
            _relationPercentage,
            _totalEmployees,
            _entryCost,
            _employeesPoints,
            _msgSender(),
            block.timestamp
        );
    }

    function removeFactoryRelation(uint256 _city, uint256 _factory) external {
        require(address(playToEarn) != address(0), INVALID_ADDRESS);
        require(address(creator) != address(0), INVALID_ADDRESS);

        require(citiesStorage.getFactoryState(_factory), INVALID_FACTORY_STATE);

        require(
            citiesStorage.getRelationState(_city, _factory),
            INVALID_RELATION
        );

        require(cities.validate(_city), INVALID_CITY);
        require(factories.validate(_factory), INVALID_FACTORY);

        CitiesLibrary.FactoryAddition memory _addition = citiesStorage
            .getFactoryAddition(_factory, _msgSender());

        CitiesLibrary.CityRelation memory _relation = citiesStorage
            .getRelationData(_city, _factory);

        require(
            _addition.active && _addition.agregator == _msgSender(),
            INVALID_ADDITION
        );

        citiesStorage.removeFactoryAddition(_factory, _msgSender());

        uint256 _totalPoints = _relation.playedPoints -
            _addition.relationPoints;

        uint256 _nextMultiplicator = _relation.multiplicator;

        if (
            _relation.multiplicator > 0 &&
            _addition.relationPoints >= citiesStorage.relevantPoints()
        ) {
            _nextMultiplicator--;
        }

        uint256 _rewards = getOwnerRelationRewards(
            _city,
            _factory,
            _msgSender()
        );

        citiesStorage.updateRelation(
            _city,
            _factory,
            calcBankrupt(_totalPoints, _relation.maxFactoryPoints),
            _relation.momentPrice,
            _totalPoints,
            _nextMultiplicator
        );

        citiesUniversities.addRelationRewards(_msgSender(), _rewards);

        removePenal[_msgSender()] = block.timestamp + removeTime;

        emit RemoveFactoryAddition(
            _city,
            _factory,
            _msgSender(),
            _rewards,
            block.timestamp
        );
    }

    function softCityRelationEnd(
        uint256 _city,
        uint256 _factory,
        uint256 _lastAgregator,
        uint256 _hardRelationPayment
    ) private {
        CitiesLibrary.CityRelation memory _relation = citiesStorage
            .getRelationData(_city, _factory);

        address[] memory _factoryAgregators = citiesStorage.getFactoryAdditions(
            _factory
        );

        for (uint256 i = 0; i < _factoryAgregators.length; i++) {
            uint256 _rewards = getOwnerRelationRewards(
                _city,
                _factory,
                _factoryAgregators[i]
            );

            citiesUniversities.addRelationRewards(
                _factoryAgregators[i],
                _rewards
            );

            citiesStorage.removeFactoryAddition(
                _factory,
                _factoryAgregators[i]
            );

            emit RemoveFactoryAddition(
                _city,
                _factory,
                _factoryAgregators[i],
                _rewards,
                block.timestamp
            );
        }

        uint256 _factoryRewards = citiesStorage.getFactoryRewards(_factory);

        citiesStorage.removeFactoryRewards(_factory, _factoryRewards);

        citiesStorage.removeCityRelation(
            _city,
            _factory,
            _relation.x,
            _relation.y
        );

        citiesUniversities.addFactoriesRewards(
            factories.ownerOf(_factory),
            _factoryRewards + _lastAgregator
        );

        emit RemoveCityRelation(
            _city,
            _factory,
            factories.ownerOf(_factory),
            _relation.x,
            _relation.y,
            _factoryRewards + _lastAgregator,
            _hardRelationPayment,
            block.timestamp
        );
    }

    function hardCityRelationEnd(
        uint256 _city,
        uint256 _factory,
        address _owner
    ) private {
        uint256 _hardRelationPayment = getHardEndPrice(_city, _factory);

        if (_hardRelationPayment > 0) {
            token.transferFrom(_owner, playToEarn, _hardRelationPayment);
        }

        softCityRelationEnd(_city, _factory, 0, _hardRelationPayment);
    }

    // Alterators

    function extractAllEmployeesPoints(
        uint256[] memory _employees,
        address _owner,
        uint8 _type,
        bool _remove
    ) private returns (CitiesLibrary.EmployeesData memory) {
        uint256 points = 0;
        uint256 sameTypes = 0;

        for (uint256 i = 0; i < _employees.length; i++) {
            require(employees.ownerOf(_employees[i]) == _owner, INVALID_OWNER);

            points += employees.getPoints(_employees[i]);

            if (!_remove) {
                require(
                    citiesStorage.canEmployeePlay(_employees[i]),
                    INVALID_EMPLOYEE
                );

                citiesStorage.playWithEmployee(_employees[i]);

                uint8[4] memory parts = employees.getParts(_employees[i]);

                for (uint256 j = 0; j < parts.length; j++) {
                    if (parts[j] == _type) sameTypes++;
                }
            }
        }

        return CitiesLibrary.EmployeesData(points, sameTypes);
    }

    function extractAllMultiEmployeesPoints(
        uint256[] memory _employees,
        address _owner,
        uint8 _type,
        bool _remove
    ) private returns (CitiesLibrary.EmployeesData memory) {
        uint256 points = 0;
        uint256 sameTypes = 0;

        for (uint256 i = 0; i < _employees.length; i++) {
            require(
                multiEmployees.ownerOf(_employees[i]) == _owner,
                INVALID_OWNER
            );

            if (multiEmployees.getType(_employees[i]) == _type) {
                sameTypes += 4;
            }

            points += multiEmployees.getPoints(_employees[i]);

            if (!_remove) {
                require(
                    citiesStorage.canMultiEmployeePlay(_employees[i]),
                    INVALID_EMPLOYEE
                );

                citiesStorage.playWithMultiEmployee(_employees[i]);
            }
        }

        return CitiesLibrary.EmployeesData(points, sameTypes);
    }

    //Validations

    function canRemoveTheRelation(uint256 _city, uint256 _factory)
        public
        view
        returns (bool)
    {
        return
            citiesStorage.getTotalFactoryAdditions(_factory) == 0 ||
            (getRemoveRelationTime(_city, _factory) <= block.timestamp);
    }

    // Calculations

    function calcRelation(
        uint256 _e,
        uint256 _m,
        uint8 _t
    ) public pure returns (uint256) {
        return _m * (((_e * _t) / 100));
    }

    function calcBankrupt(uint256 _p, uint256 _f)
        public
        pure
        returns (uint256)
    {
        return 100 - ((_p * 100) / _f);
    }

    function calculateHardEnd(
        uint256 _m,
        uint256 _p,
        uint256 _b
    ) public pure returns (uint256) {
        return ((_m * _p * _b) / 100) / 2;
    }

    function calcNextPrice(uint256 _l, uint16 _a)
        public
        pure
        returns (uint256)
    {
        return _l + ((_l * _a) / 100);
    }

    function calcAddition(
        uint256 _e,
        uint16 _a,
        uint16 _m
    ) public pure returns (uint256) {
        uint256 _r = _e / _a;
        return _r <= _m ? _r : _m;
    }

    function relationRewards(
        uint256 _m,
        uint256 _p,
        uint256 _r
    ) public pure returns (uint256) {
        return (((_m * _p * _r) * 10**18) / 100);
    }
}
