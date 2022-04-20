// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CitiesLibrary {
    struct City {
        uint256 factoryPoints;
        uint256 lands;
        uint256 world;
        uint256 university;
        uint256 townHall;
        string name;
    }

    struct CityData {
        City city;
        string uri;
    }

    struct CitiesData {
        uint8 creatorFee;
        uint8 playToEarnFee;
        uint16 pointsPerLand;
        uint256 townHallPrice;
        uint256 universityPrice;
    }

    struct RelationsData {
        uint16 relationAugmentBase;
        uint16 initialBackruptcy;
        uint16 augmentEmployees;
        uint16 relevantPoints;
        uint16 relationFactoryBase;
        uint256 entryPrice;
        uint256 resetedTime;
    }

    struct GameData {
        uint8 creatorFees;
        uint8 cityFees;
        uint8 factoryFees;
        uint8 playToEarnFees;
        CitiesLibrary.RelationsData relationsData;
    }

    struct PropertyState {
        bool state;
        bool hasRelation;
    }

    struct CityRelation {
        bool active;
        uint16 augment;
        uint256 city;
        uint256 factory;
        uint256 banckruptcyProbability;
        uint256 playedPoints;
        uint256 x;
        uint256 y;
        uint256 entryPrice;
        uint256 momentPrice;
        uint256 maxFactoryPoints;
        uint256 multiplicator;
        uint256 startTime;
    }

    struct FactoryAddition {
        bool active;
        uint256 relationPercentage;
        uint256 totalEmployees;
        uint256 entryPayment;
        uint256 relationPoints;
        address agregator;
    }

    struct EmployeesData {
        uint256 points;
        uint256 sameTypes;
    }

    struct NextProperties {
        uint8 factoryType;
        uint256 employeesPoints;
        uint256 sameTypes;
        uint256 totalPoints;
        uint256 entryCost;
        uint256 totalEmployees;
        uint256 nextMultiplicator;
        uint256 relationPercentage;
    }

    struct CityRelationProperties {
        uint256 maxFactoryPoints;
        uint256 creationPrice;
        uint256 baseMultiplier;
        uint256 maxMultiplier;
        uint256 multiplier;
    }
}
