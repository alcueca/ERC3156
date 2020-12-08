// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


interface flashBorrowerLike {
    function onFlashLoan(address user, uint256 value, uint256 fee, bytes calldata) external;
}

/**
 * @author Alberto Cuesta Cañada
 * @dev Extension of {ERC20} that allows flash minting.
 */
contract ERC20FlashMinter is ERC20 {
    using SafeMath for uint256;

    uint256 public fee;

    constructor (string memory name, string memory symbol, uint256 fee_) ERC20(name, symbol) {
        fee = fee_;
    }

    /**
     * @dev Loan `value` tokens to `receiver`, which needs to return them plus a 0.1% fee to this contract within the same transaction.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 value, uint256 fee, bytes calldata)` interface.
     * @param value The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(address receiver, uint256 value, bytes calldata data) external {
        uint256 _fee = fee == type(uint256).max ? 0 : value.div(fee);
        _mint(receiver, value);
        flashBorrowerLike(receiver).onFlashLoan(msg.sender, value, _fee, data);
        _burn(address(this), value.add(_fee));
    }
}