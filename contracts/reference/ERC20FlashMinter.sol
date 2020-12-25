// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC3156FlashBorrower, IERC3156FlashLender } from "../interfaces/IERC3156.sol";


/**
 * @author Alberto Cuesta Cañada
 * @dev Extension of {ERC20} that allows flash minting.
 */
contract ERC20FlashMinter is ERC20, IERC3156FlashLender {
    using SafeMath for uint256;

    uint256 public fee;

    constructor (string memory name, string memory symbol, uint256 fee_) ERC20(name, symbol) {
        fee = fee_;
    }

    /**
     * @dev Loan `value` tokens to `receiver`, which needs to return them plus a 0.1% fee to this contract within the same transaction.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 value, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency. Must match the address of this contract.
     * @param value The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(address receiver, address token, uint256 value, bytes calldata data) external override {
        require(token == address(this), "FlashMinter: unsupported loan currency");
        uint256 _fee = _flashFee(token, value);
        _mint(receiver, value);
        IERC3156FlashBorrower(receiver).onFlashLoan(msg.sender, token, value, _fee, data);
        _burn(address(this), value.add(_fee));
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency. Must match the address of this contract.
     * @param value The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 value) external view override returns (uint256) {
        require(token == address(this), "FlashMinter: unsupported loan currency");
        return _flashFee(token, value);
    }

    /**
     * @dev The fee to be charged for a given loan. Internal function with no checks.
     * @param token The loan currency.
     * @param value The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function _flashFee(address token, uint256 value) internal view returns (uint256) {
        return fee == type(uint256).max ? 0 : value.div(fee);
    }

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function flashSupply(address token) external view override returns (uint256) {
        return type(uint256).max;
    }
}