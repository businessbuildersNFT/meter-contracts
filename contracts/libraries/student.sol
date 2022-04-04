// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StudentsLibrary {
    struct GameResult {
        Selection selection;
        address _from;
        uint256 random;
        uint256 employee;
        bool win;
    }

    struct Selection {
        uint8 probability;
        uint16 xp;
        uint256 prize;
        uint16 points;
    }

    struct GameData {
        Selection[5] selections;
        uint64 minPlayTime;
    }
}
