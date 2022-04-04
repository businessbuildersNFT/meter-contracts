// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./libraries/employee.sol";

contract EmployeesExpanded is Context, AccessControl {
    bytes32 public constant LINK = keccak256("LINK");
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    uint8 public maxMerges = 10;

    mapping(uint256 => uint8) private employeeMerges;
    mapping(uint256 => bool) private usedForMultiEmployee;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(LINK, _msgSender());
        _setupRole(MAIN_OWNER, _msgSender());
    }

    function setMaxMerges(uint8 max) public onlyRole(MAIN_OWNER) {
        maxMerges = max;
    }

    function addMerge(uint256 id, uint8 merges) public onlyRole(LINK) {
        employeeMerges[id] += merges;
    }

    function useForMultiEmployee(uint256 id, bool used) public onlyRole(LINK) {
        usedForMultiEmployee[id] = used;
    }

    function getMergeRecord(uint256 id) public view returns (uint8) {
        return employeeMerges[id];
    }

    function canMerge(uint256 id) public view returns (bool) {
        return employeeMerges[id] < maxMerges;
    }

    function isUsedForMultiEmployee(uint256 id) public view returns (bool) {
        return usedForMultiEmployee[id];
    }
}
