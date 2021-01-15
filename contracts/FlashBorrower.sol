// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./interfaces/IERC3156FlashLender.sol";


contract FlashBorrower is IERC3156FlashBorrower {
    enum Action {NORMAL, STEAL, REENTER}

    IERC3156FlashLender lender;

    uint256 public flashBalance;
    address public flashSender;
    IERC20 public flashToken;
    uint256 public flashAmount;
    uint256 public flashFee;

    constructor (IERC3156FlashLender lender_) {
        lender = lender_;
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(address sender, IERC20 token, uint256 amount, uint256 fee, bytes calldata data) external override {
        require(msg.sender == address(lender), "FlashBorrower: Untrusted lender");
        require(sender == address(this), "FlashBorrower: External loan initiator");
        (Action action) = abi.decode(data, (Action)); // Use this to unpack arbitrary data
        flashSender = sender;
        flashToken = token;
        flashAmount = amount;
        flashFee = fee;
        if (action == Action.NORMAL) {
            flashBalance = IERC20(token).balanceOf(address(this));
        } else if (action == Action.STEAL) {
            // do nothing
        } else if (action == Action.REENTER) {
            flashBorrow(token, amount * 2);
        }
    }

    function flashBorrow(IERC20 token, uint256 amount) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.NORMAL);
        approveRepayment(token, amount);
        lender.flashLoan(this, token, amount, data);
    }

    function flashBorrowAndSteal(IERC20 token, uint256 amount) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.STEAL);
        lender.flashLoan(this, token, amount, data);
    }

    function flashBorrowAndReenter(IERC20 token, uint256 amount) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.REENTER);
        approveRepayment(token, amount);
        lender.flashLoan(this, token, amount, data);
    }

    function approveRepayment(IERC20 token, uint256 amount) public {
        uint256 _allowance = token.allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(token, amount);
        uint256 _repayment = amount + _fee;
        token.approve(address(lender), _allowance + _repayment);
    }
}
