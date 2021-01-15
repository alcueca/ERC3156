// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0 || ^0.8.0;
import "./IERC3156FlashBorrower.sol";
import "./IERC20.sol";


interface IERC3156FlashLender {

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param value The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(IERC3156FlashBorrower receiver, IERC20 token, uint256 value, bytes calldata data) external;

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param value The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(IERC20 token, uint256 value) external view returns (uint256);

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashAmount(IERC20 token) external view returns (uint256);
}