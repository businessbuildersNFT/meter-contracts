// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract ETokenController is Context, Initializable, AccessControl {
    bytes32 public constant CONNECTION = keccak256("CONNECTION");
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    string public constant INVALID_ROLE = "TC: Invalid Role";
    string public constant INVALID_ADDRESS = "TC: Invalid Address";
    string public constant INVALID_TOKENS = "TC: Invalid Amount of tokens";
    string public constant INVALID_FEES = "TC: Invalid fees payment";
    string public constant INVALID_PAYMENT = "TC: Invalid payment";
    string public constant BLACKLIST = "TC: You are in blacklist";

    mapping(address => bool) private blacklist;

    uint8 public constant CREATOR_FEE = 5;
    address public creator;

    function addConnectionContract(address connection) public virtual;

    function sendTokens(address to, uint256 amount) public virtual;

    function changeBlackListState(address bad, bool state) public virtual;
}
