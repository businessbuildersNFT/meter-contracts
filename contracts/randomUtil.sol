// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library RandomUtil {
    using SafeMath for uint256;

    function randomSeededMinMax(
        uint256 min,
        uint256 max,
        uint256 seed,
        uint256 additional
    ) internal pure returns (uint256) {
        uint256 diff = max.sub(min).add(1);

        uint256 randomVar = uint256(
            keccak256(abi.encodePacked(seed, additional))
        ).mod(diff);

        randomVar = randomVar.add(min);

        return randomVar;
    }

    function expandedRandomSeededMinMax(
        uint256 min,
        uint256 max,
        uint256 seed,
        uint256 add,
        uint256 count
    ) internal pure returns (uint256[] memory) {
        uint256[] memory randoms = new uint256[](count);
        uint256 diff = max.sub(min).add(1);

        for (uint256 i = 0; i < count; i++) {
            randoms[i] = uint256(keccak256(abi.encodePacked(seed, add, i))).mod(
                diff
            );

            randoms[i].add(min);
        }

        return randoms;
    }

    function combineSeeds(uint256 seed1, uint256 seed2)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(seed1, seed2)));
    }

    function combineSeeds(uint256[] memory seeds)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(seeds)));
    }
}
