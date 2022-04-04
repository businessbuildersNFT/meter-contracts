// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/randoms.sol";

contract TestRandoms is Randoms, Ownable {
    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(address => bool) private alreadyRequestedTestingFlag;
    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(address => bool) private seedAvailable;
    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(address => uint256) private seeds;

    uint256 private seed;

    // Views
    function getRandomSeed(address user)
        external
        view
        override
        returns (uint256)
    {
        return
            uint256(keccak256(abi.encodePacked(user, seed, block.timestamp)));
    }

    function getRandomSeedUsingHash(address user, bytes32 hash)
        external
        view
        override
        returns (uint256)
    {
        return
            uint256(
                keccak256(abi.encodePacked(user, seed, hash, block.timestamp))
            );
    }

    // Mutative
    function setRandomNumberForTestingPurposes(uint256 randomValue) external {
        seed = randomValue;
    }

    function requestRandomNumber() external override {}
}
