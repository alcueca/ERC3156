// SPDX-License-Identifier: GPL-3.0-or-later
// Derived from https://docs.aave.com/developers/guides/flash-loans
pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "../interfaces/IERC3156FlashLender.sol";
import "./interfaces/AaveFlashBorrowerLike.sol";
import "./interfaces/LendingPoolLike.sol";
import "./interfaces/LendingPoolAddressesProviderLike.sol";
import "./libraries/AaveDataTypes.sol";


/**
 * @author Alberto Cuesta Cañada
 * @dev ERC-3156 wrapper for Aave flash loans.
 */
contract AaveERC3156 is IERC3156FlashLender, AaveFlashBorrowerLike {
    using SafeMath for uint256;

    LendingPoolLike public lendingPool;

    /// @param provider Aave v2 LendingPoolAddresses address
    constructor(LendingPoolAddressesProviderLike provider) {
        lendingPool = LendingPoolLike(provider.getLendingPool());
    }

    /**
     * @dev From ERC-3156. The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashAmount(address token) external view override returns (uint256) {
        AaveDataTypes.ReserveData memory reserveData = lendingPool.getReserveData(token);
        return reserveData.aTokenAddress != address(0) ? IERC20(token).balanceOf(reserveData.aTokenAddress) : 0;
    }

    /**
     * @dev From ERC-3156. The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view override returns (uint256) {
        AaveDataTypes.ReserveData memory reserveData = lendingPool.getReserveData(token);
        require(reserveData.aTokenAddress != address(0), "Unsupported currency");
        return amount.mul(9).div(10000); // lendingPool.FLASHLOAN_PREMIUM_TOTAL()
    }

    /**
     * @dev From ERC-3156. Loan `amount` tokens to `receiver`, which needs to return them plus fee to this contract within the same transaction.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param userData A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(address receiver, address token, uint256 amount, bytes calldata userData) external override {
        address[] memory tokens = new address[](1);
        tokens[0] = address(token);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory data = abi.encode(msg.sender, receiver, userData);
        uint16 referralCode = 0;

        lendingPool.flashLoan(
            address(this),
            tokens,
            amounts,
            modes,
            onBehalfOf,
            data,
            referralCode
        );
    }

    /// @dev Aave flash loan callback. It sends the amount borrowed to `receiver`, and takes it back plus a `flashFee` after the ERC3156 callback.
    function executeOperation(
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        address sender,
        bytes calldata data
    )
        external override returns (bool)
    {
        require(msg.sender == address(lendingPool), "Callbacks only allowed from Lending Pool");
        require(sender == address(this), "Callbacks only initiated from this contract");

        (address origin, address receiver, bytes memory userData) = abi.decode(data, (address, address, bytes));

        address token = tokens[0];
        uint256 amount = amounts[0];
        uint256 fee = fees[0];

        // Send the tokens to the original receiver using the ERC-3156 interface
        IERC20(token).transfer(origin, amount);
        IERC3156FlashBorrower(receiver).onFlashLoan(origin, token, amount, fee, userData);
        IERC20(token).transferFrom(origin, address(this), amount.add(fee));

        // Approve the LendingPool contract allowance to *pull* the owed amount
        IERC20(token).approve(address(lendingPool), amount.add(fee));

        return true;
    }
}