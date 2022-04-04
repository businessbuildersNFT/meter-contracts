// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/ECityStorage.sol";
import "./libraries/cities.sol";

contract CityRelationsStorage is ECityRelationsStorage {
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

    constructor() {
        _setupRole(MAIN_OWNER, _msgSender());
        _setupRole(LINK, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // Update

    function updateResetTime() public override onlyRole(MAIN_OWNER) {
        resetedTime = block.timestamp;
    }

    function updateCitiesConfiguration(
        uint8 _maxFactoryMultiplicator,
        uint8 _maxEmployeeMultiplicator,
        uint16 _relationAugmentBase,
        uint16 _augmentEmployees,
        uint16 _relevantPoints,
        uint16 _relationFactoryBase,
        uint16 _minTime,
        uint256 _entryPrice
    ) public override onlyRole(MAIN_OWNER) {
        relationAugmentBase = _relationAugmentBase;
        entryPrice = _entryPrice;
        augmentEmployees = _augmentEmployees;
        relevantPoints = _relevantPoints;
        relationFactoryBase = _relationFactoryBase;
        minTime = _minTime;
        maxFactoryMultiplicator = _maxFactoryMultiplicator;
        maxEmployeeMultiplicator = _maxEmployeeMultiplicator;
    }

    // Validations

    function canEmployeePlay(uint256 _id) public view override returns (bool) {
        return employeesGame[_id] < resetedTime;
    }

    function canMultiEmployeePlay(uint256 _id)
        public
        view
        override
        returns (bool)
    {
        return multiEmployeesGame[_id] < resetedTime;
    }

    function canMiniEmployeePlay(uint256 _id)
        public
        view
        override
        returns (bool)
    {
        return miniEmployeesGame[_id] < resetedTime;
    }

    function canFactoryPlay(uint256 _id) public view override returns (bool) {
        return factoriesGame[_id] < resetedTime;
    }

    // Getters

    function getRelationsData()
        public
        view
        override
        returns (CitiesLibrary.RelationsData memory)
    {
        return
            CitiesLibrary.RelationsData(
                relationAugmentBase,
                initialBackruptcy,
                augmentEmployees,
                relevantPoints,
                relationFactoryBase,
                entryPrice,
                resetedTime
            );
    }

    function getFactoryState(uint256 _id) public view override returns (bool) {
        return factoryState[_id] != 0;
    }

    function getFactoryRewards(uint256 _id)
        public
        view
        override
        returns (uint256)
    {
        return factoryRewards[_id];
    }

    function getCityRewards(uint256 _id)
        public
        view
        override
        returns (uint256)
    {
        return cityRewards[_id];
    }

    function getPropertyData(
        uint256 _city,
        uint256 _x,
        uint256 _y
    ) public view override returns (CitiesLibrary.PropertyState memory) {
        return properties[_city][_x][_y];
    }

    function getRelationData(uint256 _city, uint256 _factory)
        public
        view
        override
        returns (CitiesLibrary.CityRelation memory)
    {
        return relations[_city][_factory];
    }

    function getFactoryAddition(uint256 _factory, address _owner)
        public
        view
        override
        returns (CitiesLibrary.FactoryAddition memory)
    {
        return factoryAdditions[_factory][_owner];
    }

    function getFactoryAdditionState(uint256 _factory, address _owner)
        public
        view
        override
        returns (bool)
    {
        return factoryAdditions[_factory][_owner].active;
    }

    function getRelationState(uint256 _city, uint256 _factory)
        public
        view
        override
        returns (bool)
    {
        return relations[_city][_factory].active;
    }

    function getCustomerRelations(address _customer)
        public
        view
        override
        returns (uint256[] memory)
    {
        return customerRelations[_customer];
    }

    function getFactoryAdditions(uint256 _factory)
        public
        view
        override
        returns (address[] memory)
    {
        return factoryAgregators[_factory];
    }

    function getCityRelations(uint256 _city)
        public
        view
        override
        returns (uint256[] memory)
    {
        return cityRelations[_city];
    }

    function getCityRelation(uint256 _city, uint256 _factory)
        public
        view
        override
        returns (CitiesLibrary.CityRelation memory)
    {
        return relations[_city][_factory];
    }

    function getTotalFactoryAdditions(uint256 _factory)
        public
        view
        override
        returns (uint256)
    {
        return factoryAgregators[_factory].length;
    }

    function getRelationStartTime(uint256 _city, uint256 _factory)
        public
        view
        override
        returns (uint256)
    {
        return relations[_city][_factory].startTime;
    }

    function getTotalAgregatorAdditions(address _agregator)
        public
        view
        override
        returns (uint256)
    {
        return customerRelations[_agregator].length;
    }

    function getTotalCityRelations(uint256 _city)
        public
        view
        override
        returns (uint256)
    {
        return cityRelations[_city].length;
    }

    function getUniversityRewards(uint256 _city)
        public
        view
        override
        returns (uint256)
    {
        return universityRewards[_city];
    }

    function getUniversityMultiplicator(uint256 _city)
        public
        view
        override
        returns (uint256)
    {
        return universityMultiplicator[_city];
    }

    function getUniversityAdditions(uint256 _city)
        public
        view
        override
        returns (uint256)
    {
        return totalUniversityAdditions[_city];
    }

    function getRelationMomentPrice(uint256 _city, uint256 _factory)
        public
        view
        override
        returns (uint256)
    {
        return relations[_city][_factory].momentPrice;
    }

    function getRelationMultiplicator(uint256 _city, uint256 _factory)
        public
        view
        override
        returns (uint256)
    {
        return relations[_city][_factory].multiplicator;
    }

    // Alterators

    function changeFactoryState(uint256 _id, uint256 _city)
        public
        override
        onlyRole(LINK)
    {
        factoryState[_id] = _city;
    }

    function addFactoryRewards(uint256 _id, uint256 _amount)
        public
        override
        onlyRole(LINK)
    {
        factoryRewards[_id] += _amount;
    }

    function removeFactoryRewards(uint256 _id, uint256 _amount)
        public
        override
        onlyRole(LINK)
    {
        require(factoryRewards[_id] >= _amount, INVALID_REWARDS);
        factoryRewards[_id] -= _amount;
    }

    function addCityRewards(uint256 _id, uint256 _amount)
        public
        override
        onlyRole(LINK)
    {
        cityRewards[_id] += _amount;
    }

    function removeCityRewards(uint256 _id, uint256 _amount)
        public
        override
        onlyRole(LINK)
    {
        require(cityRewards[_id] >= _amount, INVALID_REWARDS);
        cityRewards[_id] -= _amount;
    }

    function playWithEmployee(uint256 _id) public override onlyRole(LINK) {
        employeesGame[_id] = block.timestamp;
    }

    function playWithEmployees(uint256[] memory _ids)
        public
        override
        onlyRole(LINK)
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            employeesGame[_ids[i]] = block.timestamp;
        }
    }

    function playWithMultiEmployee(uint256 _id) public override onlyRole(LINK) {
        multiEmployeesGame[_id] = block.timestamp;
    }

    function playWithMultiEmployees(uint256[] memory _ids)
        public
        override
        onlyRole(LINK)
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            multiEmployeesGame[_ids[i]] = block.timestamp;
        }
    }

    function playWithMiniEmployee(uint256 _id) public override onlyRole(LINK) {
        miniEmployeesGame[_id] = block.timestamp;
    }

    function playWithMiniEmployees(uint256[] memory _ids)
        public
        override
        onlyRole(LINK)
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            miniEmployeesGame[_ids[i]] = block.timestamp;
        }
    }

    function changePropertyState(
        uint256 _city,
        uint256 _x,
        uint256 _y,
        bool _state
    ) public override onlyRole(LINK) {
        properties[_city][_x][_y].state = _state;
    }

    function addCityRelation(
        uint256 _city,
        uint256 _factory,
        uint256 _x,
        uint256 _y,
        uint256 _maxPoints
    ) public override onlyRole(LINK) {
        properties[_city][_x][_y].hasRelation = true;
        factoryState[_factory] = _city;
        cityRelations[_city].push(_factory);

        relations[_city][_factory] = CitiesLibrary.CityRelation(
            true,
            relationAugmentBase,
            _city,
            _factory,
            initialBackruptcy,
            0,
            _x,
            _y,
            entryPrice,
            entryPrice,
            _maxPoints,
            0,
            block.timestamp
        );
    }

    function removeCityRelation(
        uint256 _city,
        uint256 _factory,
        uint256 _x,
        uint256 _y
    ) public override onlyRole(LINK) {
        properties[_city][_x][_y].hasRelation = false;
        factoryState[_factory] = 0;
        relations[_city][_factory].active = false;
        factoryAgregators[_factory] = new address[](0);
        factoryRewards[_factory] = 0;

        for (uint256 i = 0; i < cityRelations[_city].length; i++) {
            if (cityRelations[_city][i] == _factory) {
                cityRelations[_city][i] = cityRelations[_city][
                    cityRelations[_city].length - 1
                ];

                cityRelations[_city].pop();
                break;
            }
        }
    }

    function addFactoryAddition(
        uint256 _percentage,
        uint256 _factory,
        uint256 _employees,
        uint256 _entry,
        uint256 _points,
        address _agregator
    ) public override onlyRole(LINK) {
        customerRelations[_agregator].push(_factory);
        factoryAgregators[_factory].push(_agregator);

        factoryAdditions[_factory][_agregator] = CitiesLibrary.FactoryAddition(
            true,
            _percentage,
            _employees,
            _entry,
            _points,
            _agregator
        );
    }

    function removeFactoryAddition(uint256 _factory, address _agregator)
        public
        override
        onlyRole(LINK)
    {
        for (uint256 i = 0; i < customerRelations[_agregator].length; i++) {
            if (customerRelations[_agregator][i] == _factory) {
                customerRelations[_agregator][i] = customerRelations[
                    _agregator
                ][customerRelations[_agregator].length - 1];

                customerRelations[_agregator].pop();
                break;
            }
        }

        for (uint256 i = 0; i < factoryAgregators[_factory].length; i++) {
            if (factoryAgregators[_factory][i] == _agregator) {
                factoryAgregators[_factory][i] = factoryAgregators[_factory][
                    factoryAgregators[_factory].length - 1
                ];

                factoryAgregators[_factory].pop();
                break;
            }
        }

        factoryAdditions[_factory][_agregator].active = false;
    }

    function updateRelation(
        uint256 _city,
        uint256 _factory,
        uint256 _banckruptcyProbability,
        uint256 _momentPrice,
        uint256 _playedPoints,
        uint256 _multiplicator
    ) public override onlyRole(LINK) {
        require(
            _multiplicator <= maxFactoryMultiplicator,
            INVALID_MULTIPLICATOR
        );

        relations[_city][_factory].momentPrice = _momentPrice;
        relations[_city][_factory].playedPoints = _playedPoints;
        relations[_city][_factory].multiplicator = _multiplicator;

        relations[_city][_factory]
            .banckruptcyProbability = _banckruptcyProbability;
    }

    function addUniversityRewards(uint256 _city, uint256 _amount)
        public
        override
        onlyRole(LINK)
    {
        universityRewards[_city] += _amount;
    }

    function removeUniversityRewards(uint256 _city, uint256 _amount)
        public
        override
        onlyRole(LINK)
    {
        require(universityRewards[_city] >= _amount, INVALID_REWARDS);
        universityRewards[_city] -= _amount;
    }

    function changeUniversityMultiplicator(
        uint256 _city,
        uint256 _multiplicator
    ) public override onlyRole(LINK) {
        universityMultiplicator[_city] = _multiplicator;
    }

    function changeUniversityAdditions(uint256 _city, uint256 _add)
        public
        override
        onlyRole(LINK)
    {
        totalUniversityAdditions[_city] = _add;
    }
}
