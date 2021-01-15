// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "../interfaces/IERC3156FlashLender.sol";


/**
 * @author Alberto Cuesta Cañada
 * @dev Extension of {ERC20} that allows flash lending.
 */
contract FlashLender is IERC3156FlashLender {

    mapping(IERC20 => bool) public supportedTokens;
    uint256 public fee; //  1 == 0.0001 %.


    /**
     * @param supportedTokens_ Token contracts supported for flash lending.
     * @param fee_ The percentage of the loan `amount` that needs to be repaid, in addition to `amount`.
     */
    constructor(IERC20[] memory supportedTokens_, uint256 fee_) {
        for (uint256 i = 0; i < supportedTokens_.length; i++) {
            supportedTokens[supportedTokens_[i]] = true;
        }
        fee = fee_;
    }

    /**
     * @dev Loan `amount` tokens to `receiver`, and takes it back plus a `flashFee` after the callback.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(IERC3156FlashBorrower receiver, IERC20 token, uint256 amount, bytes calldata data) external override {
        require(supportedTokens[token], "FlashLender: Unsupported currency");
        uint256 fee = _flashFee(token, amount);
        token.transfer(address(receiver), amount);
        receiver.onFlashLoan(msg.sender, token, amount, fee, data);
        token.transferFrom(address(receiver), address(this), amount + fee);
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(IERC20 token, uint256 amount) external view override returns (uint256) {
        require(supportedTokens[token], "FlashLender: Unsupported currency");
        return _flashFee(token, amount);
    }

    /**
     * @dev The fee to be charged for a given loan. Internal function with no checks.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function _flashFee(IERC20 token, uint256 amount) internal view returns (uint256) {
        return amount * fee / 10000;
    }

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashAmount(IERC20 token) external view override returns (uint256) {
        return supportedTokens[token] ? token.balanceOf(address(this)) : 0;
    }
}