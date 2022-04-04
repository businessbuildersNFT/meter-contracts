// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * This Token only works on testnet
 * You can find mainnet token in
 * 0x5e03437D73425F2aaB981E538D73296A70f11Af4
 * https://bscscan.com/address/0x5e03437D73425F2aaB981E538D73296A70f11Af4
 * https://app.unicrypt.network/amm/pancake-v2/ilo/0xc45e7DA5e756d97e5b780762422F177a817b4332
 */

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 * Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.1/contracts/examples/SimpleToken.sol
 */
contract Token is ERC20 {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _mint(address(this), 100000000000 * (10**uint256(decimals())));
        _approve(address(this), msg.sender, totalSupply());
    }
}
