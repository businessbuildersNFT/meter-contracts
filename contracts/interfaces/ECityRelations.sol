// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ETeamLeaderValidations.sol";
import "./EUniversitiesStorage.sol";
import "../libraries/cities.sol";
import "./ECityStorage.sol";
import "./EBBERC721.sol";
import "../factory.sol";
import "../cities.sol";

abstract contract ECityRelations is Initializable, Context, AccessControl {
    struct CityRelationEvent {
        uint256 city;
        uint256 factory;
        address agregator;
        uint256 x;
        uint256 y;
        uint256 payment;
        uint256 maxFactoryPoints;
        uint256 maxMultiplier;
        uint256 time;
    }

    struct RemoveCityRelationEvent {
        uint256 city;
        uint256 factory;
        address agregator;
        uint256 x;
        uint256 y;
        uint256 multiplicator;
        uint256 rewards;
        uint256 hardPayment;
        uint256 time;
    }

    struct FactoryAdditionEvent {
        uint256 city;
        uint256 factory;
        address agregator;
        uint256 relationPercentage;
        uint256 totalEmployees;
        uint256 entryPayment;
        uint256 relationPoints;
        uint256 maxMultiplier;
        uint256 time;
    }

    struct RemoveFactoryAdditionEvent {
        uint256 city;
        uint256 factory;
        address agregator;
        uint256 rewards;
        uint256 multiplier;
        uint256 time;
    }

    event CityRelation(CityRelationEvent);
    event RemoveCityRelation(RemoveCityRelationEvent);
    event FactoryAddition(FactoryAdditionEvent);
    event RemoveFactoryAddition(RemoveFactoryAdditionEvent);
    event ChangePropertyState(uint256 city, uint256 x, uint256 y);

    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_CITY_SPACES = "CR: Not enought spaces";
    string public constant INVALID_PROPERTY_STATE = "CR: Invalid property";
    string public constant HAS_RELATION = "CR: The property has a relation";
    string public constant INVALID_OWNER = "CR: Invalid owner";
    string public constant INVALID_FACTORY_STATE = "CR: Invalid factory";
    string public constant INVALID_PAYMENT = "CR: Invalid payment";
    string public constant INVALID_EMPLOYEES = "CR: Invalid employees";
    string public constant INVALID_CITY = "CR: Invalid city";
    string public constant INVALID_FACTORY = "CR: Invalid factory";
    string public constant INVALID_RELATION = "CR: Invalid relation";
    string public constant INVALID_RELATION_STATE = "CR: Invalid state";
    string public constant INVALID_ADDRESS = "CR: Invalid address";
    string public constant INVALID_ADDITION = "CR: Invalid addition";
    string public constant INVALID_EMPLOYEE = "CR: Invalid employee";
    string public constant INVALID_MULTIPLICATOR = "CR: Invalid multiplicator";

    address public creator;
    address public playToEarn;
    uint256 public resetedTime;
}
