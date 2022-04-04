// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Builder {
    struct Data {
        address tokenReceiver;
        address creator;
        uint256 buildPrice;
        uint8 CREATOR_FEE;
        uint8 LIQUIDITY_FEE;
    }

    struct Request {
        uint256 id;
        address owner;
        string imageUrl;
        bool isValid;
        bool accepted;
        bool deployed;
    }
}
