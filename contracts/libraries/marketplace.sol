// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

library Marketplace {
    struct Sell {
        address nft;
        address seller;
        uint256 id;
        uint256 price;
        bool exists;
    }

    struct ProductInfo {
        string image;
        string name;
        address owner;
        address token;
        address nft;
        uint8 royalties;
        uint8 marketFees;
        bool open;
        bool status;
    }
}
