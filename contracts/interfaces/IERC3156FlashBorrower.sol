// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0 || ^0.8.0;


interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param sender The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function onFlashLoan(
        address sender,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bool);
}
