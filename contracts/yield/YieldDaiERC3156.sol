// SPDX-License-Identifier: GPL-3.0-or-later
// Derived from https://github.com/yieldprotocol/fyDai-flash
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libraries/YieldMath.sol";
import "./libraries/SafeCast.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "../interfaces/IERC3156FlashLender.sol";
import "./interfaces/YieldFlashBorrowerLike.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IFYDai.sol";


/**
 * YieldDaiLender allows ERC-3156 Dai flash loans out of a YieldSpace pool, by flash minting fyDai and selling it to the pool.
 */
contract YieldDaiERC3156 is IERC3156FlashLender, YieldFlashBorrowerLike {
    using SafeCast for uint256;
    using SafeMath for uint256;

    IPool public pool;

    /// @param pool_ One of Yield Pool addresses
    constructor (IPool pool_) {
        pool = pool_;

        // Allow pool to take dai and fyDai for trading
        if (pool.dai().allowance(address(this), address(pool)) < type(uint256).max)
            pool.dai().approve(address(pool), type(uint256).max);
        if (pool.fyDai().allowance(address(this), address(pool)) < type(uint112).max)
            pool.fyDai().approve(address(pool), type(uint256).max);
    }

    /**
     * @dev From ERC-3156. The amount of currency available to be lended.
     * @param token The loan currency. It must be Dai.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashAmount(address token) public view override returns (uint256) {
        return token == address(pool.dai()) ? pool.getDaiReserves() : 0;
    }

    /**
     * @dev From ERC-3156. The fee to be charged for a given loan.
     * @param token The loan currency. It must be Dai.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) public view override returns (uint256) {
        require(token == address(pool.dai()), "Unsupported currency");
        uint128 fyDaiAmount = pool.buyDaiPreview(amount.toUint128());

        // To obtain the result of a trade on hypothetical reserves we need to call the YieldMath library
        uint256 daiRepaid = YieldMath.daiInForFYDaiOut(
            (uint256(pool.getDaiReserves()).sub(amount)).toUint128(),    // Dai reserves minus Dai we just bought
            (uint256(pool.getFYDaiReserves()).add(fyDaiAmount)).toUint128(),  // fyDai reserves plus fyDai we just sold
            fyDaiAmount,                                                        // fyDai flash mint we have to repay
            (pool.fyDai().maturity() - block.timestamp).toUint128(),                      // This can't be called after maturity
            int128(uint256((1 << 64)) / 126144000),                             // 1 / Seconds in 4 years, in 64.64
            int128(uint256((950 << 64)) / 1000)                                 // Fees applied when selling Dai to the pool, in 64.64
        );

        return daiRepaid.sub(amount);
    }

    /**
     * @dev From ERC-3156. Loan `amount` Dai to `receiver`, which needs to return them plus fee to this contract within the same transaction.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency. Must be the dai address associated with the `pool`.
     * @param amount The amount of tokens lent.
     * @param userData A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes memory userData) public override {
        require(token == address(pool.dai()), "Unsupported currency");
        bytes memory data = abi.encode(msg.sender, receiver, amount, userData);
        uint256 fyDaiAmount = pool.buyDaiPreview(amount.toUint128());
        pool.fyDai().flashMint(fyDaiAmount, data); // Callback from fyDai will come back to this contract
    }

    /// @dev FYDai flash loan callback. It sends the value borrowed to `receiver`, and expects that the value plus the fee will be transferred back.
    function executeOnFlashMint(uint256 fyDaiAmount, bytes memory data) public override {
        require(msg.sender == address(pool.fyDai()), "Callbacks only allowed from fyDai contract");

        (address origin, IERC3156FlashBorrower receiver, uint256 amount, bytes memory userData) = 
            abi.decode(data, (address, IERC3156FlashBorrower, uint256, bytes));

        uint256 paidFYDai = pool.buyDai(address(this), address(receiver), amount.toUint128());

        uint256 fee = uint256(pool.buyFYDaiPreview(fyDaiAmount.toUint128())).sub(amount);
        receiver.onFlashLoan(origin, address(pool.dai()), amount, fee, userData);
        pool.dai().transferFrom(address(receiver), address(this), amount.add(fee));
        pool.sellDai(address(this), address(this), amount.add(fee).toUint128());
    }
}
