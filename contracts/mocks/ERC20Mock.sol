// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {

    constructor (string memory name, string memory symbol) ERC20(name, symbol) {}

    /// @dev Give free tokens to anyone
    function mint(address receiver, uint256 value) external {
        _mint(receiver, value);
    }
}