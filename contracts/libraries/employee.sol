// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library EmployeeLibrary {
    struct EmployeeNFT {
        uint8 head;
        uint8 body;
        uint8 legs;
        uint8 hands;
        uint16 points;
    }

    struct EmployeeNFTData {
        EmployeeNFT employee;
        string uri;
    }

    struct EmployeeNFTExpanded {
        EmployeeNFTData employee;
        uint256 burnTokens;
    }

    struct EmployeeURI {
        uint8 head;
        uint8 body;
        uint8 hands;
        uint8 legs;
        uint16 points;
        uint256 id;
    }

    struct EmployeeChildrenNFT {
        uint8 head;
        uint8 body;
        uint8 legs;
        uint8 hands;
        uint8 net;
        uint16 xp;
        uint16 points;
    }

    struct EmployeeChildrenNFTData {
        EmployeeChildrenNFT employee;
        string uri;
    }

    struct EmployeesData {
        uint256 price;
        uint8 creatorFee;
        uint8 playToEarnFee;
    }

    struct EmployeeChildrenNFTExpanded {
        EmployeeChildrenNFTData employee;
        uint16 merges;
    }
}
