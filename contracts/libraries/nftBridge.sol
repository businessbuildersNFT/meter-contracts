// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library NFTBridgeLibrary {
    struct LimboRequest {
        address fromContract;
        address sender;
        uint256 id;
        uint256[] nfts;
    }

    struct ReleaseFromLimbo {
        address fromContract;
        address sender;
        uint256[] nfts;
    }

    struct StorageData {
        bool open;
        uint8 maxNFTs;
        uint256 feePerNFT;
    }

    struct SavedMinted {
        address nft;
        address owner;
        uint256[] nfts;
    }

    struct expropiateMany {
        address nft;
        address owner;
        uint256[] nfts;
    }
}
