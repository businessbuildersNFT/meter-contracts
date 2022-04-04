// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./libraries/employee.sol";
import "./libraries/factory.sol";
import "./employee.sol";
import "./factory.sol";
import "./miniEmployee.sol";
import "./multiEmployee.sol";

contract NFTBridgeMinter is Initializable, Context, AccessControl {
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");
    address public creator;

    Employees employees;
    Factories factories;
    MultiEmployees multiEmployees;
    MiniEmployees miniEmployees;

    function initialize(
        address _employees,
        address _miniEmployees,
        address _multiEmployees,
        address _factories
    ) external initializer {
        creator = msg.sender;
        _setupRole(MAIN_OWNER, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        employees = Employees(_employees);
        miniEmployees = MiniEmployees(_miniEmployees);
        factories = Factories(_factories);
        multiEmployees = MultiEmployees(_multiEmployees);
    }

    function mintEmployees(
        EmployeeLibrary.EmployeeNFT[] memory _employees,
        address _owner
    ) external onlyRole(MAIN_OWNER) {
        for (uint256 i = 0; i < _employees.length; i++) {
            employees.mint(
                _employees[i].head,
                _employees[i].body,
                _employees[i].legs,
                _employees[i].hands,
                _employees[i].points,
                _owner
            );
        }
    }

    function mintMultiEmployees(
        EmployeeLibrary.EmployeeNFT[] memory _employees,
        address _owner
    ) external onlyRole(MAIN_OWNER) {
        for (uint256 i = 0; i < _employees.length; i++) {
            multiEmployees.mint(
                _employees[i].head,
                _employees[i].body,
                _employees[i].legs,
                _employees[i].hands,
                _employees[i].points,
                _owner
            );
        }
    }

    function mintFactories(
        FactoryLibrary.FactoryNFT[] memory _factories,
        address _owner
    ) external onlyRole(MAIN_OWNER) {
        for (uint256 i = 0; i < _factories.length; i++) {
            factories.mint(
                _factories[i].build,
                _factories[i].model,
                _factories[i].points,
                _owner
            );
        }
    }

    function mintMiniEmployees(
        EmployeeLibrary.EmployeeChildrenNFT[] memory _employees,
        address _owner
    ) external onlyRole(MAIN_OWNER) {
        for (uint256 i = 0; i < _employees.length; i++) {
            miniEmployees.mint(
                _employees[i].head,
                _employees[i].body,
                _employees[i].legs,
                _employees[i].hands,
                0,
                _employees[i].points,
                _owner
            );
        }
    }

    function levelUpMiniEmployees(
        uint256[] memory _employees,
        uint16[] memory levels
    ) external onlyRole(MAIN_OWNER) {
        for (uint256 i = 0; i < _employees.length; i++) {
            miniEmployees.levelUp(_employees[i], levels[i]);
        }
    }
}
