// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./cities.sol";

library UniversitiesLibrary {
    struct Rewards {
        uint256 cityRewards;
        uint256 factoryRewards;
        uint256 relationsRewards;
        uint256 miniEmployeeRewards;
        uint256 universitiesXP;
    }

    struct UniversityInfo {
        uint256 multiplicator;
        uint256 totalRewards;
        uint256 additions;
        uint256 lockedPoints;
        uint256 baseCityMultiplier;
    }

    struct FactoryRelationInfo {
        CitiesLibrary.PropertyState property;
        CitiesLibrary.CityRelation relation;
        CitiesLibrary.FactoryAddition addition;
        uint256 cityRewards;
        uint256 factoryRewards;
    }
}
