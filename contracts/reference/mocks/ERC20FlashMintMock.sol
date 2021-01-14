// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../FlashMinter.sol";

contract FlashMinterMock is FlashMinter {

    constructor (string memory name, string memory symbol, uint256 fee) FlashMinter(name, symbol, fee) {}

    /// @dev Give free tokens to anyone
    function mint(address receiver, uint256 value) external {
        _mint(receiver, value);
    }
}