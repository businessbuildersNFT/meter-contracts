// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface BBERC721 is IERC721 {
    function burn(uint256) external;

    function validate(uint256) external view returns (bool);

    function isOwnerOfAll(address, uint256[] calldata)
        external
        view
        returns (bool);

    function getPoints(uint256) external returns (uint16);

    function getType(uint256) external returns (uint8);

    function getParts(uint256) external returns (uint8[4] memory);
}
