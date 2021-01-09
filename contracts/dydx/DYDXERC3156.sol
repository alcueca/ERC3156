// SPDX-License-Identifier: GPL-3.0-or-later
// Derived from https://github.com/kollateral/kollateral/blob/master/protocol/contracts/liquidity/kollateral/KollateralLiquidityProxy.sol
pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "../interfaces/IERC3156FlashLender.sol";
import "./interfaces/SoloMarginLike.sol";
import "./interfaces/DYDXFlashBorrowerLike.sol";
import "./libraries/DYDXDataTypes.sol";
import "@nomiclabs/buidler/console.sol";


contract DYDXERC3156 is IERC3156FlashLender, DYDXFlashBorrowerLike {
    using SafeMath for uint256;

    uint256 internal NULL_ACCOUNT_ID = 0;
    uint256 internal NULL_MARKET_ID = 0;
    DYDXDataTypes.AssetAmount internal NULL_AMOUNT = DYDXDataTypes.AssetAmount({
        sign: false,
        denomination: DYDXDataTypes.AssetDenomination.Wei,
        ref: DYDXDataTypes.AssetReference.Delta,
        value: 0
    });
    bytes internal NULL_DATA = "";

    SoloMarginLike public soloMargin;
    mapping(address => uint256) public tokenAddressToMarketId;
    mapping(address => bool) public tokensRegistered;

    /// @param soloMargin_ DYDX SoloMargin address
    constructor (SoloMarginLike soloMargin_) {
        soloMargin = soloMargin_;

        for (uint256 marketId = 0; marketId <= 2; marketId++) {
            address token = soloMargin.getMarketTokenAddress(marketId);
            tokenAddressToMarketId[token] = marketId;
            tokensRegistered[token] = true;
        }
    }

    /**
     * @dev From ERC-3156. The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashAmount(address token) external view override returns (uint256) {
        return tokensRegistered[token] == true ? IERC20(token).balanceOf(address(soloMargin)) : 0;
    }

    /**
     * @dev From ERC-3156. The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) public view override returns (uint256) {
        require(tokensRegistered[token], "Unsupported currency");
        return 2;
    }

    /**
     * @dev From ERC-3156. Loan `value` tokens to `receiver`, which needs to return them plus fee to this contract within the same transaction.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 value, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param userData A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(address receiver, address token, uint256 amount, bytes memory userData) external override {
        DYDXDataTypes.ActionArgs[] memory operations = new DYDXDataTypes.ActionArgs[](3);
        operations[0] = getWithdrawAction(token, amount);
        operations[1] = getCallAction(abi.encode(msg.sender, receiver, token, amount, userData));
        operations[2] = getDepositAction(token, amount.add(flashFee(token, amount)));
        DYDXDataTypes.AccountInfo[] memory accountInfos = new DYDXDataTypes.AccountInfo[](1);
        accountInfos[0] = getAccountInfo();

        soloMargin.operate(accountInfos, operations);
    }

    /// @dev DYDX flash loan callback. It sends the value borrowed to `receiver`, and takes it back plus a `flashFee` after the ERC3156 callback.
    function callFunction(
        address sender,
        DYDXDataTypes.AccountInfo memory,
        bytes memory data
    )
    public override
    {
        require(msg.sender == address(soloMargin), "Callback only from SoloMargin");
        require(sender == address(this), "FlashLoan only from this contract");

        (address origin, address receiver, address token, uint256 amount, bytes memory userData) = 
            abi.decode(data, (address, address, address, uint256, bytes));

        uint256 fee = flashFee(token, amount);

        // Transfer to `receiver`
        require(IERC20(token).transfer(receiver, amount), "Transfer failed");
        IERC3156FlashBorrower(receiver).onFlashLoan(origin, token, amount, fee, userData);
        require(IERC20(token).transferFrom(receiver, address(this), amount.add(fee)), "Transfer failed");

        // Approve the SoloMargin contract allowance to *pull* the owed amount
        IERC20(token).approve(address(soloMargin), amount.add(fee));            
    }

    function getAccountInfo() internal view returns (DYDXDataTypes.AccountInfo memory) {
        return DYDXDataTypes.AccountInfo({
            owner: address(this),
            number: 1
        });
    }

    function getWithdrawAction(address token, uint256 amount)
    internal
    view
    returns (DYDXDataTypes.ActionArgs memory)
    {
        return DYDXDataTypes.ActionArgs({
            actionType: DYDXDataTypes.ActionType.Withdraw,
            accountId: 0,
            amount: DYDXDataTypes.AssetAmount({
                sign: false,
                denomination: DYDXDataTypes.AssetDenomination.Wei,
                ref: DYDXDataTypes.AssetReference.Delta,
                value: amount
            }),
            primaryMarketId: tokenAddressToMarketId[token],
            secondaryMarketId: NULL_MARKET_ID,
            otherAddress: address(this),
            otherAccountId: NULL_ACCOUNT_ID,
            data: NULL_DATA
        });
    }

    function getDepositAction(address token, uint256 repaymentAmount)
    internal
    view
    returns (DYDXDataTypes.ActionArgs memory)
    {
        return DYDXDataTypes.ActionArgs({
            actionType: DYDXDataTypes.ActionType.Deposit,
            accountId: 0,
            amount: DYDXDataTypes.AssetAmount({
                sign: true,
                denomination: DYDXDataTypes.AssetDenomination.Wei,
                ref: DYDXDataTypes.AssetReference.Delta,
                value: repaymentAmount
            }),
            primaryMarketId: tokenAddressToMarketId[token],
            secondaryMarketId: NULL_MARKET_ID,
            otherAddress: address(this),
            otherAccountId: NULL_ACCOUNT_ID,
            data: NULL_DATA
        });
    }

    function getCallAction(bytes memory data_)
    internal
    view
    returns (DYDXDataTypes.ActionArgs memory)
    {
        return DYDXDataTypes.ActionArgs({
            actionType: DYDXDataTypes.ActionType.Call,
            accountId: 0,
            amount: NULL_AMOUNT,
            primaryMarketId: NULL_MARKET_ID,
            secondaryMarketId: NULL_MARKET_ID,
            otherAddress: address(this),
            otherAccountId: NULL_ACCOUNT_ID,
            data: data_
        });
    }
}