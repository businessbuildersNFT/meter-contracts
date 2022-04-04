// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library FactoryStakingLibrary {
    struct Factory {
        address owner;
        uint256 factory;
        uint256 timestamp;
    }

    struct Info {
        uint256 inStakeFactories;
        uint256 inStakeCustomers;
        uint256 inStakePoints;
    }

    struct Customer {
        Factory[] stakedFactories;
        uint256 minterPoints;
        uint256 savedMinterPoints;
    }

    struct SendRewards {
        uint256 customerRewards;
        uint256 timestamp;
    }
}
