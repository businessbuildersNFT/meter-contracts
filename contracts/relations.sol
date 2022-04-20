// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./libraries/relations.sol";
import "./interfaces/randoms.sol";
import "./tokenController.sol";
import "./randomUtil.sol";
import "./employee.sol";
import "./multiEmployee.sol";
import "./factory.sol";

contract RelationsGame is Initializable, AccessControl {
    event PlayRelations(RelationsLibrary.GameResult);

    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_FACTORIES = "RG: Invalid factories.";
    string public constant INVALID_EMPLOYEES = "RG: Invalid employees.";
    string public constant NULL_REWARDS = "RG: Null rewards.";

    Randoms private randoms;
    Employees private employees;
    MultiEmployees private multiEmployees;
    Factories private factories;
    TokenController private manager;

    mapping(uint256 => uint256) private _factoryPlayTime;
    mapping(uint256 => uint256) private _employeePlayTime;
    mapping(uint256 => uint256) private _multiEmployeePlayTime;
    mapping(address => uint256) private _playRewards;

    uint16 private _randomCounter = 1;

    uint256 public playRelationsBase = 4000000000000000000 wei;
    uint32 public minPlayTime = 86400;

    function initialize(
        Factories _factories,
        Employees _employees,
        MultiEmployees _multiEmployees,
        Randoms _randoms,
        TokenController _manager
    ) public initializer {
        _setupRole(MAIN_OWNER, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        employees = _employees;
        multiEmployees = _multiEmployees;
        factories = _factories;
        manager = _manager;
        randoms = _randoms;
    }

    // Getters

    function getEmployeePlayTime(uint256 id, bool multi)
        public
        view
        returns (uint256)
    {
        return multi ? _multiEmployeePlayTime[id] : _employeePlayTime[id];
    }

    function getFactoryPlayTime(uint256 id) public view returns (uint256) {
        return _factoryPlayTime[id];
    }

    function getPlayRewards(address owner) public view returns (uint256) {
        return _playRewards[owner];
    }

    // Setters

    function setplayRelationsBase(uint256 amount) public {
        playRelationsBase = amount;
    }

    function setMinPlayTime(uint32 time) public onlyRole(MAIN_OWNER) {
        minPlayTime = time;
    }

    function addToRandomCounter() private {
        if (_randomCounter < 250) _randomCounter++;
        else _randomCounter = 0;
    }

    //Customers

    function requestTokens() public {
        require(_playRewards[msg.sender] > 1, NULL_REWARDS);
        manager.sendTokens(msg.sender, _playRewards[msg.sender] - 1);
        _playRewards[msg.sender] = 1;
    }

    // Game

    function playWithFactory(
        uint256 factory,
        uint256[] memory employeeIds,
        uint256[] memory multiIds
    ) public {
        require(
            employeeIds.length > 0 || multiIds.length > 0,
            INVALID_EMPLOYEES
        );

        require(canFactoryPlay(msg.sender, factory), INVALID_FACTORIES);

        require(
            allEmployeesCanPlay(msg.sender, multiIds, true),
            INVALID_EMPLOYEES
        );

        require(
            allEmployeesCanPlay(msg.sender, employeeIds, false),
            INVALID_EMPLOYEES
        );

        uint256 random;
        uint256 types = 0;
        uint256 sinergy = 0;
        uint256 points = factories.getMultiplier(factory);
        uint8 factoryType = factories.getType(factory);

        random = RandomUtil.randomSeededMinMax(
            0,
            99,
            randoms.getRandomSeed(msg.sender),
            _randomCounter
        );

        addToRandomCounter();

        for (uint8 i = 0; i < employeeIds.length; i++) {
            uint8[4] memory parts = employees.getParts(employeeIds[i]);

            for (uint8 j = 0; j < parts.length; j++) {
                if (factoryType == parts[j]) types++;
            }

            points += employees.getPoints(employeeIds[i]);
            _employeePlayTime[employeeIds[i]] = block.timestamp;
        }

        for (uint8 i = 0; i < multiIds.length; i++) {
            uint8[4] memory parts = multiEmployees.getParts(multiIds[i]);

            for (uint8 j = 0; j < parts.length; j++) {
                if (factoryType == parts[j]) types++;
            }

            points += multiEmployees.getPoints(multiIds[i]);
            _multiEmployeePlayTime[multiIds[i]] = block.timestamp;
        }

        sinergy = ((types * 100) /
            ((employeeIds.length + multiIds.length) * 4));

        if (random < sinergy) {
            _playRewards[msg.sender] += points * playRelationsBase;
        }

        _factoryPlayTime[factory] = block.timestamp;

        emit PlayRelations(
            RelationsLibrary.GameResult(
                msg.sender,
                random,
                (random < sinergy),
                (random < sinergy) ? points : 0,
                sinergy
            )
        );
    }

    // Questions

    function canFactoryPlay(address owner, uint256 id)
        public
        view
        returns (bool)
    {
        return
            (_factoryPlayTime[id] <= block.timestamp - minPlayTime) &&
            factories.validate(id) &&
            factories.ownerOf(id) == owner;
    }

    function canEmployeePlay(
        address owner,
        uint256 id,
        bool multi
    ) public view returns (bool) {
        return
            multi
                ? (_multiEmployeePlayTime[id] <=
                    block.timestamp - minPlayTime) &&
                    multiEmployees.validate(id) &&
                    multiEmployees.ownerOf(id) == owner
                : (_employeePlayTime[id] <= block.timestamp - minPlayTime) &&
                    employees.validate(id) &&
                    employees.ownerOf(id) == owner;
    }

    function allEmployeesCanPlay(
        address owner,
        uint256[] memory employee,
        bool multi
    ) public view returns (bool) {
        for (uint8 i = 0; i < employee.length; i++) {
            if (!canEmployeePlay(owner, employee[i], multi)) return false;
        }

        return true;
    }
}
