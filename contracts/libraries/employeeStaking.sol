// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library EmployeeStakingLibrary {
    struct Employee {
        address owner;
        uint256 employee;
    }

    struct Info {
        uint256 inStakeEmployees;
        uint256 stakedTokens;
        uint256 inStakeCustomers;
        uint256 inStakePoints;
        uint256 divideStart;
    }

    struct Customer {
        uint256 stakedRewards;
        uint256 stakedPoints;
        uint256[] stakedEmployees;
    }

    struct SendRewards {
        uint256 customerRewards;
        uint256 totalBalance;
        uint256 totalCustomers;
        uint256 totalStakingPoints;
    }
}
