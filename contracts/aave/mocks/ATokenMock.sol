// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../mocks/ERC20Mock.sol";


contract ATokenMock is ERC20Mock {

    IERC20 public underlying;
    constructor (IERC20 underlying_, string memory name, string memory symbol) ERC20Mock(name, symbol) {
        underlying = underlying_;
    }

    function transferUnderlyingTo(address to, uint256 amount) external {
        underlying.transfer(to, amount); // Remember to mint some tokens for ATokenMock first
    }
}