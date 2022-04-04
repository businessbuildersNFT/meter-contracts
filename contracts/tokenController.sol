// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract TokenController is Context, Initializable, AccessControl {
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

    ERC20 private token;

    address public creator;

    function initialize(ERC20 _token) public initializer {
        _setupRole(ROLE_ADMIN, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        creator = _msgSender();
        token = _token;
    }

    function addConnectionContract(address connection)
        public
        onlyRole(ROLE_ADMIN)
    {
        grantRole(CONNECTION, connection);
    }

    function sendTokens(address to, uint256 amount)
        public
        onlyRole(CONNECTION)
    {
        require(!blacklist[to], BLACKLIST);
        require(token.balanceOf(address(this)) > amount, INVALID_TOKENS);

        token.transfer(creator, (amount * CREATOR_FEE) / 100);
        token.transfer(to, (amount * (100 - CREATOR_FEE)) / 100);
    }

    function changeBlackListState(address bad, bool state) public onlyRole(ROLE_ADMIN) {
        blacklist[bad] = state;
    }
}
