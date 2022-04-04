// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library FactoryLibrary {
    struct FactoryNFT {
        uint8 build;
        uint8 model;
        uint256 points;
    }

    struct FactoryNFTData {
        FactoryNFT factory;
        string uri;
    }

    struct FactoryNFTExpanded {
        FactoryNFTData factory;
        uint256 burnTokens;
    }

    struct FactoryURI {
        uint8 build;
        uint8 model;
        uint256 multiplier;
        uint256 id;
    }

    struct FactoriesData {
        uint256 price;
        uint8 burnEmployees;
        uint8 creatorFee;
        uint8 playToEarnFee;
    }

    struct DeployerData {
        uint8[] buildTypes;
        uint8[] buildModels;
        uint16[] typeProbabilities;
        uint16 probabilitiesTotal;
    }
}
