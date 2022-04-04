// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Randoms {
    // Views
    function getRandomSeed(address user) external view returns (uint256 seed);

    function getRandomSeedUsingHash(address user, bytes32 hash)
        external
        view
        returns (uint256 seed);

    function requestRandomNumber() external;
}
