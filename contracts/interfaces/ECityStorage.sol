// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../libraries/cities.sol";

abstract contract ECityRelationsStorage is Context, AccessControl {
    event NewCityRelation(CitiesLibrary.CityRelation);

    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");
    bytes32 public constant LINK = keccak256("LINK");

    mapping(uint256 => uint256) private factoryState; // Factory => City
    mapping(uint256 => uint256) private factoryRewards; // Factory => Rewards
    mapping(uint256 => uint256) private cityRewards; // City => Rewards

    mapping(address => uint256[]) private customerRelations; // User => Factories
    mapping(uint256 => address[]) private factoryAgregators; // Factory => Agregator
    mapping(uint256 => uint256[]) private cityRelations; // City => Factories

    mapping(uint256 => uint256) private universityMultiplicator; // City => University multiplicator
    mapping(uint256 => uint256) private totalUniversityAdditions; // City => University Additions
    mapping(uint256 => uint256) private universityRewards; // City => Rewards

    mapping(uint256 => uint256) private employeesGame; // Employee => Timestamp
    mapping(uint256 => uint256) private miniEmployeesGame; // Employee => Timestamp
    mapping(uint256 => uint256) private multiEmployeesGame; // Employee => Timestamp
    mapping(uint256 => uint256) private factoriesGame; // Factory => Timestamp

    mapping(uint256 => mapping(address => CitiesLibrary.FactoryAddition))
        private factoryAdditions; // Factory => Additions

    mapping(uint256 => mapping(uint256 => mapping(uint256 => CitiesLibrary.PropertyState)))
        private properties; // City => x => y => active

    mapping(uint256 => mapping(uint256 => CitiesLibrary.CityRelation))
        private relations; // City => Factory => Relation

    string public constant INVALID_REWARDS = "CRS: Invalid rewards";
    string public constant INVALID_MULTIPLICATOR = "CRS: Invalid multiplicator";

    uint8 public maxFactoryMultiplicator = 40;
    uint8 public maxEmployeeMultiplicator = 10;
    uint16 public relationAugmentBase = 1;
    uint16 public initialBackruptcy = 100;
    uint16 public augmentEmployees = 5;
    uint16 public relevantPoints = 10;
    uint16 public relationFactoryBase = 50;
    uint32 public minTime = 86400;
    uint256 public entryPrice = 30000000000000000000;
    uint256 public resetedTime = 0;


    // Update

    function updateResetTime() public virtual;

    function updateCitiesConfiguration(
        uint8 _maxFactoryMultiplicator,
        uint8 _maxEmployeeMultiplicator,
        uint16 _relationAugmentBase,
        uint16 _augmentEmployees,
        uint16 _relevantPoints,
        uint16 _relationFactoryBase,
        uint16 _minTime,
        uint256 _entryPrice
    ) public virtual;

    // Validations

    function canEmployeePlay(uint256 _id) public view virtual returns (bool);

    function canMultiEmployeePlay(uint256 _id)
        public
        view
        virtual
        returns (bool);

    function canMiniEmployeePlay(uint256 _id)
        public
        view
        virtual
        returns (bool);

    function canFactoryPlay(uint256 _id) public view virtual returns (bool);

    // Getters

    function getRelationsData()
        public
        view
        virtual
        returns (CitiesLibrary.RelationsData memory);

    function getFactoryState(uint256 _id) public view virtual returns (bool);

    function getFactoryRewards(uint256 _id)
        public
        view
        virtual
        returns (uint256);

    function getCityRewards(uint256 _id) public view virtual returns (uint256);

    function getPropertyData(
        uint256 _city,
        uint256 _x,
        uint256 _y
    ) public view virtual returns (CitiesLibrary.PropertyState memory);

    function getRelationData(uint256 _city, uint256 _factory)
        public
        view
        virtual
        returns (CitiesLibrary.CityRelation memory);

    function getFactoryAddition(uint256 _factory, address _owner)
        public
        view
        virtual
        returns (CitiesLibrary.FactoryAddition memory);

    function getRelationState(uint256 _city, uint256 _factory)
        public
        view
        virtual
        returns (bool);

    function getCustomerRelations(address _customer)
        public
        view
        virtual
        returns (uint256[] memory);

    function getFactoryAdditions(uint256 _factory)
        public
        view
        virtual
        returns (address[] memory);

    function getCityRelations(uint256 _city)
        public
        view
        virtual
        returns (uint256[] memory);

    function getCityRelation(uint256 _city, uint256 _factory)
        public
        view
        virtual
        returns (CitiesLibrary.CityRelation memory);

    function getTotalFactoryAdditions(uint256 _factory)
        public
        view
        virtual
        returns (uint256);

    function getRelationStartTime(uint256 _city, uint256 _factory)
        public
        view
        virtual
        returns (uint256);

    function getTotalAgregatorAdditions(address _agregator)
        public
        view
        virtual
        returns (uint256);

    function getTotalCityRelations(uint256 _city)
        public
        view
        virtual
        returns (uint256);

    function getUniversityRewards(uint256 _city)
        public
        view
        virtual
        returns (uint256);

    function getFactoryAdditionState(uint256 _factory, address _agregator)
        public
        view
        virtual
        returns (bool);

    function getUniversityMultiplicator(uint256 _city)
        public
        view
        virtual
        returns (uint256);

    function getUniversityAdditions(uint256 _city)
        public
        view
        virtual
        returns (uint256);

    function getRelationMomentPrice(uint256 _city, uint256 _factory)
        public
        view
        virtual
        returns (uint256);

    function getRelationMultiplicator(uint256 _city, uint256 _factory)
        public
        view
        virtual
        returns (uint256);

    // Alterators

    function changeFactoryState(uint256 _id, uint256 _city) public virtual;

    function addFactoryRewards(uint256 _id, uint256 _amount) public virtual;

    function removeFactoryRewards(uint256 _id, uint256 _amount) public virtual;

    function addCityRewards(uint256 _id, uint256 _amount) public virtual;

    function removeCityRewards(uint256 _id, uint256 _amount) public virtual;

    function playWithEmployee(uint256 _id) public virtual;

    function playWithEmployees(uint256[] memory _ids) public virtual;

    function playWithMultiEmployee(uint256 _id) public virtual;

    function playWithMultiEmployees(uint256[] memory _ids) public virtual;

    function playWithMiniEmployee(uint256 _id) public virtual;

    function playWithMiniEmployees(uint256[] memory _ids) public virtual;

    function changePropertyState(
        uint256 _city,
        uint256 _x,
        uint256 _y,
        bool _state
    ) public virtual;

    function addCityRelation(
        uint256 _city,
        uint256 _factory,
        uint256 _x,
        uint256 _y,
        uint256 _maxPoints
    ) public virtual;

    function removeCityRelation(
        uint256 _city,
        uint256 _factory,
        uint256 _x,
        uint256 _y
    ) public virtual;

    function addFactoryAddition(
        uint256 _percentage,
        uint256 _factory,
        uint256 _employees,
        uint256 _entry,
        uint256 _points,
        address _agregator
    ) public virtual;

    function removeFactoryAddition(uint256 _factory, address _agregator)
        public
        virtual;

    function updateRelation(
        uint256 _city,
        uint256 _factory,
        uint256 _banckruptcyProbability,
        uint256 _momentPrice,
        uint256 _playedPoints,
        uint256 _multiplicator
    ) public virtual;

    function addUniversityRewards(uint256 _city, uint256 _amount)
        public
        virtual;

    function removeUniversityRewards(uint256 _city, uint256 _amount)
        public
        virtual;

    function changeUniversityMultiplicator(
        uint256 _city,
        uint256 _multiplicator
    ) public virtual;

    function changeUniversityAdditions(uint256 _city, uint256 _add)
        public
        virtual;
}
