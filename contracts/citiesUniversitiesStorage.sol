// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/EUniversitiesStorage.sol";

contract CityUniversitiesStorage is ECityUniversitiesStorage {
    mapping(uint256 => uint256) private factoriesGame; // Factory => Timestamp
    mapping(uint256 => uint256) private totalLockedPoints; // City => Points
    mapping(uint256 => uint256) private baseCityMultiplier; // City => Multiplier
    mapping(address => uint256) private universityXP; // City => XP
    mapping(address => uint256) private relationsRewards; // Owner => Rewards
    mapping(address => uint256) private factoriesRewards; // Owner => Rewards
    mapping(address => uint256) private miniEmployeesRewards; // Owner => Rewards

    bool public validateSpecificTime = true;
    uint32 public factoriesTime = 86400;
    uint32 public resetedTime;

    constructor() {
        _setupRole(MAIN_OWNER, _msgSender());
        _setupRole(LINK, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    //Getters

    function getLockedPoints(uint256 _city)
        public
        view
        override
        returns (uint256)
    {
        return totalLockedPoints[_city];
    }

    function getBaseCityMultiplier(uint256 _city)
        public
        view
        override
        returns (uint256)
    {
        return baseCityMultiplier[_city];
    }

    function getUniversitiesXP(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return universityXP[_owner];
    }

    function getRelationsRewards(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return relationsRewards[_owner];
    }

    function getFactoriesRewards(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return factoriesRewards[_owner];
    }

    function getMiniEmployeesRewards(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return miniEmployeesRewards[_owner];
    }

    // Alterators

    function updateTimeMethod() public override onlyRole(MAIN_OWNER) {
        validateSpecificTime = !validateSpecificTime;
    }

    function addRelationRewards(address _owner, uint256 _rewards)
        public
        override
        onlyRole(LINK)
    {
        relationsRewards[_owner] += _rewards;
    }

    function addMiniEmployeesRewards(address _owner, uint256 _rewards)
        public
        override
        onlyRole(LINK)
    {
        miniEmployeesRewards[_owner] += _rewards;
    }

    function removeMiniEmployeesRewards(address _owner, uint256 _rewards)
        public
        override
        onlyRole(LINK)
    {
        miniEmployeesRewards[_owner] -= _rewards;
    }

    function removeRelationRewards(address _owner, uint256 _rewards)
        public
        override
        onlyRole(LINK)
    {
        relationsRewards[_owner] -= _rewards;
    }

    function addFactoriesRewards(address _owner, uint256 _rewards)
        public
        override
        onlyRole(LINK)
    {
        factoriesRewards[_owner] += _rewards;
    }

    function removeFactoriesRewards(address _owner, uint256 _rewards)
        public
        override
        onlyRole(LINK)
    {
        factoriesRewards[_owner] -= _rewards;
    }

    function updateLockedPoints(uint256 _city, uint256 _points)
        public
        override
        onlyRole(LINK)
    {
        totalLockedPoints[_city] = _points;
    }

    function addLockedPoints(uint256 _city, uint256 _points)
        public
        override
        onlyRole(LINK)
    {
        totalLockedPoints[_city] += _points;
    }

    function removeLockedPoints(uint256 _city, uint256 _points)
        public
        override
        onlyRole(LINK)
    {
        totalLockedPoints[_city] -= _points;
    }

    function updateCitiesMultiplier(uint256 _city, uint256 _multiplier)
        public
        override
        onlyRole(LINK)
    {
        baseCityMultiplier[_city] = _multiplier;
    }

    function playWithFactory(uint256 _factory) public override onlyRole(LINK) {
        factoriesGame[_factory] = block.timestamp + factoriesTime;
    }

    function updateUniversityXP(address _owner, uint256 _xp)
        public
        override
        onlyRole(LINK)
    {
        universityXP[_owner] = _xp;
    }

    function addUniversityXP(address _owner, uint256 _xp)
        public
        override
        onlyRole(LINK)
    {
        universityXP[_owner] += _xp;
    }

    function removeUniversityXP(address _owner, uint256 _xp)
        public
        override
        onlyRole(LINK)
    {
        universityXP[_owner] -= _xp;
    }

    //Validators

    function canFactoryPlay(uint256 _factory)
        public
        view
        override
        returns (bool)
    {
        return
            validateSpecificTime
                ? factoriesGame[_factory] < block.timestamp
                : factoriesGame[_factory] < resetedTime;
    }
}
