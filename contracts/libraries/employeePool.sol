// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

library EmployeePoolLibrary {
    struct PageInfo {
        uint256 inJobEmployees;
        uint256 inJobCustomers;
        uint256 maxInJobEmployees;
        uint256 totalRewards;
        uint256 totalJobPoints;
        uint256 momentJobEnd;
        uint256 momentJobStart;
        bool hasActiveJob;
    }

    struct Prices {
        uint256 hireEmployeePrice;
    }

    struct CustomerInfo {
        uint64 customerPoints;
        uint16 inJobEmployees;
    }

    struct SendEmployeeToJob {
        address _from;
        uint256 employee;
        uint16 points;
    }

    struct StartNewJob {
        address admin;
        uint256 start;
        uint256 finish;
    }

    struct FinishJob {
        address winner;
        uint256 amount;
        uint256 pointsToWin;
    }
}
