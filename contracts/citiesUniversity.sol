// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/universities.sol";
import "./cities.sol";
import "./employee.sol";
import "./miniEmployee.sol";
import "./tokenController.sol";
import "./cityRelationsStorage.sol";
import "./citiesUniversitiesStorage.sol";

contract CityUniversities is Initializable, Context, AccessControl {
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_CITY = "CR: Invalid city";
    string public constant INVALID_EMPLOYEE = "CR: Invalid employee";
    string public constant INVALID_UNIVERSITY = "CR: Invalid university";
    string public constant INVALID_OWNER = "CR: Invalid owner";

    Cities private cities;
    Employees private employees;
    MiniEmployees private miniEmployees;
    TokenController private tokenController;
    CityUniversitiesStorage private citiesUniversities;
    CityRelationsStorage private citiesStorage;

    bool private openUniversityTokenRewards = true;

    uint8 public miniEmployeesFlush = 20;
    uint8 public experienceToUniversity = 10;
    uint16 public pointsToAddBaseMultiplier = 1000;

    function initialize(
        TokenController _tokenController,
        Employees _employees,
        MiniEmployees _miniEmployees,
        Cities _cities,
        CityUniversitiesStorage _citiesUniversities,
        CityRelationsStorage _citiesStorage
    ) external initializer {
        _setupRole(MAIN_OWNER, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        employees = _employees;
        miniEmployees = _miniEmployees;
        cities = _cities;
        tokenController = _tokenController;
        citiesUniversities = _citiesUniversities;
        citiesStorage = _citiesStorage;
    }

    //Update

    function toggleUniversityRewards() external onlyRole(MAIN_OWNER) {
        openUniversityTokenRewards = !openUniversityTokenRewards;
    }

    function updatePointsToBase(uint16 _points) external onlyRole(MAIN_OWNER) {
        pointsToAddBaseMultiplier = _points;
    }

    function updateMiniFlush(uint8 _days) external onlyRole(MAIN_OWNER) {
        miniEmployeesFlush = _days;
    }

    function updateUniversityXP(uint8 _xp) external onlyRole(MAIN_OWNER) {
        experienceToUniversity = _xp;
    }

    // Getters

    function getUserRewards(address _owner)
        external
        view
        returns (UniversitiesLibrary.Rewards memory)
    {
        return
            UniversitiesLibrary.Rewards(
                getCitiesRewards(_owner),
                citiesUniversities.getFactoriesRewards(_owner),
                citiesUniversities.getRelationsRewards(_owner),
                citiesUniversities.getMiniEmployeesRewards(_owner),
                citiesUniversities.getUniversitiesXP(_owner)
            );
    }

    function getUniversityInfo(uint256 _city)
        external
        view
        returns (UniversitiesLibrary.UniversityInfo memory)
    {
        return
            UniversitiesLibrary.UniversityInfo(
                citiesStorage.getUniversityMultiplicator(_city),
                citiesStorage.getUniversityRewards(_city),
                citiesStorage.getUniversityAdditions(_city),
                citiesUniversities.getLockedPoints(_city),
                citiesUniversities.getBaseCityMultiplier(_city)
            );
    }

    function getFactoryRelationInfo(
        uint256 _city,
        uint256 _factory,
        uint256 _x,
        uint256 _y,
        address _owner
    ) external view returns (UniversitiesLibrary.FactoryRelationInfo memory) {
        return
            UniversitiesLibrary.FactoryRelationInfo(
                citiesStorage.getPropertyData(_city, _x, _y),
                citiesStorage.getCityRelation(_city, _factory),
                citiesStorage.getFactoryAddition(_factory, _owner),
                citiesStorage.getCityRewards(_city),
                citiesStorage.getFactoryRewards(_factory)
            );
    }

    function getCitiesRewards(address _owner) public view returns (uint256) {
        uint256 _citiesBalance = cities.balanceOf(_owner);

        if (_citiesBalance > 0) {
            uint256 _totalRewards = 0;

            for (uint256 i = 0; i < _citiesBalance; i++) {
                _totalRewards += citiesStorage.getCityRewards(
                    cities.tokenOfOwnerByIndex(_owner, i)
                );
            }

            return _totalRewards;
        } else return 0;
    }

    // Alterators

    function sendMiniEmployeeToTheUniversity(
        uint256 _city,
        uint256[] memory _employees
    ) external {
        require(cities.validate(_city), INVALID_CITY);
        require(cities.hasUniversity(_city), INVALID_UNIVERSITY);

        uint256 _totalXP = 0;

        for (uint256 i = 0; i < _employees.length; i++) {
            require(
                miniEmployees.validate(_employees[i]) &&
                    miniEmployees.ownerOf(_employees[i]) == _msgSender() &&
                    citiesStorage.canMiniEmployeePlay(_employees[i]),
                INVALID_EMPLOYEE
            );

            uint16 _lastXP = miniEmployees.getXP(_employees[i]);
            uint16 _employeePoints = miniEmployees.getPoints(_employees[i]);
            uint16 _neccesaryXP = _employeePoints * 100;

            uint16 _employeeXP = (_neccesaryXP / miniEmployeesFlush) *
                (miniEmployees.getSpecial(_employees[i]) ? 2 : 1);

            if (_lastXP + _employeeXP >= _neccesaryXP) {
                uint8[4] memory _parts = miniEmployees.getParts(_employees[i]);

                employees.mint(
                    _parts[0],
                    _parts[1],
                    _parts[2],
                    _parts[3],
                    _employeePoints,
                    _msgSender()
                );

                miniEmployees.burn(_employees[i]);
            } else {
                citiesStorage.playWithMiniEmployee(_employees[i]);
                miniEmployees.levelUp(_employees[i], _employeeXP);
            }

            _totalXP += _employeeXP;
        }

        citiesStorage.changeUniversityAdditions(
            _city,
            citiesStorage.getUniversityAdditions(_city) + _employees.length
        );

        if (experienceToUniversity > 0) {
            citiesUniversities.addUniversityXP(
                cities.ownerOf(_city),
                ((_totalXP > 10 ? _totalXP : 10) * experienceToUniversity) / 100
            );
        }

        if (openUniversityTokenRewards) {
            citiesUniversities.addMiniEmployeesRewards(
                _msgSender(),
                citiesStorage.getUniversityMultiplicator(_city) *
                    _employees.length
            );
        }
    }

    function lockMiniEmployeesInTheUniversity(
        uint256 _city,
        uint256[] memory _employees
    ) external {
        require(cities.validate(_city), INVALID_CITY);
        require(cities.hasUniversity(_city), INVALID_UNIVERSITY);

        uint256 _totalPoints = citiesUniversities.getLockedPoints(_city);

        for (uint256 i = 0; i < _employees.length; i++) {
            require(miniEmployees.validate(_employees[i]), INVALID_EMPLOYEE);
            miniEmployees.burn(_employees[i]);
            _totalPoints += miniEmployees.getPoints(_employees[i]);
        }

        citiesUniversities.updateLockedPoints(_city, _totalPoints);

        citiesUniversities.updateCitiesMultiplier(
            _city,
            _totalPoints / pointsToAddBaseMultiplier
        );
    }

    function withdrawRelationsRewards() external {
        uint256 _rewards = citiesUniversities.getRelationsRewards(_msgSender());

        if (_rewards > 0) {
            tokenController.sendTokens(_msgSender(), _rewards);
            citiesUniversities.removeRelationRewards(_msgSender(), _rewards);
        }
    }

    function withdrawFactoriesRewards() external {
        uint256 _rewards = citiesUniversities.getFactoriesRewards(_msgSender());

        if (_rewards > 0) {
            tokenController.sendTokens(_msgSender(), _rewards);
            citiesUniversities.removeFactoriesRewards(_msgSender(), _rewards);
        }
    }

    function withdrawMiniEmployeesRewards() external {
        uint256 _rewards = citiesUniversities.getMiniEmployeesRewards(
            _msgSender()
        );

        if (_rewards > 0) {
            tokenController.sendTokens(_msgSender(), _rewards);
            citiesUniversities.removeMiniEmployeesRewards(
                _msgSender(),
                _rewards
            );
        }
    }

    function withdrawCityRewards() external {
        uint256 _citiesBalance = cities.balanceOf(_msgSender());

        if (_citiesBalance > 0) {
            uint256 _totalRewards = 0;

            for (uint256 i = 0; i < _citiesBalance; i++) {
                uint256 _token = cities.tokenOfOwnerByIndex(_msgSender(), i);
                uint256 _partialRewards = citiesStorage.getCityRewards(_token);
                _totalRewards += _partialRewards;
                citiesStorage.removeCityRewards(_token, _partialRewards);
            }

            tokenController.sendTokens(_msgSender(), _totalRewards);
        }
    }

    function upgradeEmployeesWithXP(uint256[] memory _employees) external {
        require(
            miniEmployees.isOwnerOfAll(_msgSender(), _employees),
            INVALID_OWNER
        );

        uint256 _totalXP = citiesUniversities.getUniversitiesXP(_msgSender());

        for (uint256 i = 0; i < _employees.length; i++) {
            uint16 _employeePoints = miniEmployees.getPoints(_employees[i]);
            uint256 _necessaryXP = _employeePoints * 100;

            if (_totalXP >= _necessaryXP) {
                uint8[4] memory _parts = miniEmployees.getParts(_employees[i]);

                employees.mint(
                    _parts[0],
                    _parts[1],
                    _parts[2],
                    _parts[3],
                    _employeePoints,
                    _msgSender()
                );

                miniEmployees.burn(_employees[i]);

                _totalXP -= _necessaryXP;
            } else {
                miniEmployees.levelUp(_employees[i], uint16(_totalXP));
                _totalXP = 0;
            }
        }

        citiesUniversities.updateUniversityXP(_msgSender(), _totalXP);
    }
}
