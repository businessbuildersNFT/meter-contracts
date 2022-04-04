// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract ECityUniversitiesStorage is Context, AccessControl {
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");
    bytes32 public constant LINK = keccak256("LINK");

    string public constant INVALID_UNIVERSITY = "CR: Invalid university";
    string public constant INVALID_EMPLOYEE = "CR: Invalid employee";
    string public constant INVALID_CITY = "CR: Invalid city";

    //Getters

    function getLockedPoints(uint256 _city)
        public
        view
        virtual
        returns (uint256);

    function getBaseCityMultiplier(uint256 _city)
        public
        view
        virtual
        returns (uint256);

    function getUniversitiesXP(address _owner)
        public
        view
        virtual
        returns (uint256);

    // Alterators

    function updateTimeMethod() public virtual;

    function updateLockedPoints(uint256 _city, uint256 _points) public virtual;

    function addLockedPoints(uint256 _city, uint256 _points) public virtual;

    function removeLockedPoints(uint256 _city, uint256 _points) public virtual;

    function addMiniEmployeesRewards(address _owner, uint256 _rewards)
        public
        virtual;

    function removeMiniEmployeesRewards(address _owner, uint256 _rewards)
        public
        virtual;

    function getMiniEmployeesRewards(address _owner)
        public
        view
        virtual
        returns (uint256);

    function getRelationsRewards(address _owner)
        public
        view
        virtual
        returns (uint256);

    function getFactoriesRewards(address _owner)
        public
        view
        virtual
        returns (uint256);

    function updateCitiesMultiplier(uint256 _city, uint256 _multiplier)
        public
        virtual;

    function addRelationRewards(address _owner, uint256 _rewards)
        public
        virtual;

    function removeRelationRewards(address _owner, uint256 _rewards)
        public
        virtual;

    function addFactoriesRewards(address _owner, uint256 _rewards)
        public
        virtual;

    function removeFactoriesRewards(address _owner, uint256 _rewards)
        public
        virtual;

    function playWithFactory(uint256 _factory) public virtual;

    function updateUniversityXP(address _owner, uint256 _xp) public virtual;

    function addUniversityXP(address _owner, uint256 _xp) public virtual;

    function removeUniversityXP(address _owner, uint256 _xp) public virtual;

    //Validators

    function canFactoryPlay(uint256 _factory)
        public
        view
        virtual
        returns (bool);
}
