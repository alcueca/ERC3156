// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.5;

import "../ERC20FlashMinter.sol";

contract ERC20FlashMinterMock is ERC20FlashMinter {

    constructor (string memory name, string memory symbol, uint256 fee) ERC20FlashMinter(name, symbol, fee) {}

    /// @dev Give free tokens to anyone
    function mint(address receiver, uint256 value) external {
        _mint(receiver, value);
    }
}