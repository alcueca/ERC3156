// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libraries/YieldMath.sol";
import "./libraries/SafeCast.sol";
import { IERC3156FlashBorrower, IERC3156FlashLender } from "../interfaces/IERC3156.sol";
import "./interfaces/YieldFlashBorrowerLike.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IFYDai.sol";


/**
 * YieldDaiLender allows ERC-3156 Dai flash loans out of a YieldSpace pool, by flash minting fyDai and selling it to the pool.
 */
contract YieldDaiERC3156 is IERC3156FlashLender, YieldFlashBorrowerLike {
    using SafeCast for uint256;
    using SafeMath for uint256;

    IPool public lender;

    function setLender(IPool lender_) public {
        lender = lender_;

        // Allow lender to take dai and fyDai for trading
        if (lender.dai().allowance(address(this), address(lender)) < type(uint256).max)
            lender.dai().approve(address(lender), type(uint256).max);
        if (lender.fyDai().allowance(address(this), address(lender)) < type(uint112).max)
            lender.fyDai().approve(address(lender), type(uint256).max);
    }

    /// @dev Fee charged on top of a Dai flash loan.
    function flashFee(address dai, uint256 daiBorrowed) public view override returns (uint256) {
        require(dai == address(lender.dai()), "Unsupported Dai contract");
        uint128 fyDaiAmount = lender.buyDaiPreview(daiBorrowed.toUint128());

        // To obtain the result of a trade on hypothetical reserves we need to call the YieldMath library
        uint256 daiRepaid = YieldMath.daiInForFYDaiOut(
            (uint256(lender.getDaiReserves()).sub(daiBorrowed)).toUint128(),    // Dai reserves minus Dai we just bought
            (uint256(lender.getFYDaiReserves()).add(fyDaiAmount)).toUint128(),  // fyDai reserves plus fyDai we just sold
            fyDaiAmount,                                                        // fyDai flash mint we have to repay
            (lender.fyDai().maturity() - block.timestamp).toUint128(),                      // This can't be called after maturity
            int128(uint256((1 << 64)) / 126144000),                             // 1 / Seconds in 4 years, in 64.64
            int128(uint256((950 << 64)) / 1000)                                 // Fees applied when selling Dai to the lender, in 64.64
        );

        return daiRepaid.sub(daiBorrowed);
    }

    /// @dev Maximum Dai flash loan available.
    function flashSupply(address dai) public view override returns (uint256) {
        require(dai == address(lender.dai()), "Unsupported Dai contract");
        return lender.getDaiReserves();
    }

    /// @dev Borrow `daiAmount` as a flash loan.
    function flashLoan(address receiver, address dai, uint256 daiAmount, bytes memory data) public override {
        require(dai == address(lender.dai()), "Unsupported Dai contract");
        bytes memory wrappedData = abi.encode(data, msg.sender, receiver, daiAmount);
        uint256 fyDaiAmount = lender.buyDaiPreview(daiAmount.toUint128());
        lender.fyDai().flashMint(fyDaiAmount, wrappedData); // Callback from fyDai will come back to this contract
    }

    /// @dev FYDai `flashMint` callback.
    function executeOnFlashMint(uint256 fyDaiAmount, bytes memory wrappedData) public override {
        require(msg.sender == address(lender.fyDai()), "Callbacks only allowed from fyDai contract");

        (bytes memory data, address sender, address receiver, uint256 daiAmount) = abi.decode(wrappedData, (bytes, address, address, uint256));

        uint256 paidFYDai = lender.buyDai(address(this), address(this), daiAmount.toUint128());

        uint256 fee = uint256(lender.buyFYDaiPreview(fyDaiAmount.toUint128())).sub(daiAmount);
        IERC3156FlashBorrower(receiver).onFlashLoan(sender, address(lender.dai()), daiAmount, fee, data);
        // Before the end of the transaction, `receiver` must `transfer` the `loanAmount` plus the `fee`
        // to this contract so that the conversions that repay the loan are done.
        lender.sellDai(address(this), address(this), daiAmount.add(fee).toUint128());
    }
}
