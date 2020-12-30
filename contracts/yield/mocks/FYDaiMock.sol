// SPDX-License-Identifier: GPL-3.0-or-later
// Derived from https://github.com/yieldprotocol/fyDai
pragma solidity ^0.7.5;

import "../interfaces/YieldFlashBorrowerLike.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract FYDaiMock is ERC20  {

    uint256 public maturity;

    constructor(string memory name, string memory symbol, uint256 maturity_) ERC20(name, symbol) {
        maturity = maturity_;
    }

    /// @dev Flash-mint fyDai. Calls back on `YieldFlashBorrowerLike.executeOnFlashMint()`
    /// @param fyDaiAmount Amount of fyDai to mint.
    /// @param data User-defined data to pass on to `executeOnFlashMint()`
    function flashMint(uint256 fyDaiAmount, bytes calldata data) external {
        _mint(msg.sender, fyDaiAmount);
        YieldFlashBorrowerLike(msg.sender).executeOnFlashMint(fyDaiAmount, data);
        _burn(msg.sender, fyDaiAmount);
    }

    /// @dev Mint fyDai.
    /// @param to Wallet to mint the fyDai in.
    /// @param fyDaiAmount Amount of fyDai to mint.
    function mint(address to, uint256 fyDaiAmount) public {
        _mint(to, fyDaiAmount);
    }

    /// @dev Burn fyDai.
    /// @param from Wallet to burn the fyDai from.
    /// @param fyDaiAmount Amount of fyDai to burn.
    function burn(address from, uint256 fyDaiAmount) public {
        _burn(from, fyDaiAmount);
    }

    /// @dev Creates `fyDaiAmount` tokens and assigns them to `to`, increasing the total supply, up to a limit of 2**112.
    /// @param to Wallet to mint the fyDai in.
    /// @param fyDaiAmount Amount of fyDai to mint.
    function _mint(address to, uint256 fyDaiAmount) internal override {
        super._mint(to, fyDaiAmount);
        require(totalSupply() <= 5192296858534827628530496329220096, "FYDai: Total supply limit exceeded"); // 2**112
    }
}
