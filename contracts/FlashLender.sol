// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


interface flashBorrowerLike {
    function onFlashLoan(address user, address token, uint256 value, uint256 fee, bytes calldata) external;
}

/**
 * @author Alberto Cuesta Cañada
 * @dev Extension of {ERC20} that allows flash lending.
 */
contract FlashLender {
    using SafeMath for uint256;

    address public immutable currency1;
    address public immutable currency2;
    uint256 public fee;

    constructor(address currency1_, address currency2_, uint256 fee_) {
        currency1 = currency1_;
        currency2 = currency2_;
        fee = fee_;
    }

    /**
     * @dev Loan `value` tokens to `receiver`, which needs to return them plus a 0.1% fee to this contract within the same transaction.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 value, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency.
     * @param value The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(address receiver, address token, uint256 value, bytes calldata data) external {
        require(
            token == currency1 || token == currency2,
            "FlashLender: unsupported loan currency"
        );
        IERC20 currency = IERC20(token);
        uint256 _fee = _flashFee(token, value);
        uint256 balanceTarget = currency.balanceOf(address(this)).add(_fee);
        currency.transfer(receiver, value);
        flashBorrowerLike(receiver).onFlashLoan(msg.sender, token, value, _fee, data);
        require(currency.balanceOf(address(this)) >= balanceTarget, "FlashLender: unpaid loan");
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param value The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 value) external view returns (uint256) {
        require(
            token == currency1 || token == currency2,
            "FlashLender: unsupported loan currency"
        );
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
    function flashSupply(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}