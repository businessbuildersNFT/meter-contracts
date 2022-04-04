// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library RelationsLibrary {
    struct GameResult {
        address _from;
        uint256 random;
        bool win;
        uint256 amount;
        uint256 chemistry;
    }
}
