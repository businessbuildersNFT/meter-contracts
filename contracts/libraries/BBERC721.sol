// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface BBERC721 is IERC721 {
    function burn(uint256 id) external;

    function validate(uint256 id) external view returns (bool);

    function isOwnerOfAll(address owner, uint256[] calldata ids)
        external
        view
        returns (bool);

    function mint(
        uint8 head,
        uint8 body,
        uint8 legs,
        uint8 hands,
        uint16 points,
        address to
    ) external;
}
