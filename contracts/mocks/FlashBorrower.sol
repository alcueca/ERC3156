// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;
import "@nomiclabs/buidler/console.sol";


interface FlashLenderLike {
    function flashLoan(address receiver, address token, uint256 value, bytes calldata) external;
}

interface ERC20Like {
    function balanceOf(address) external returns (uint256);
    function transfer(address, uint256) external;
}

contract FlashBorrower {
    enum Action {NORMAL, STEAL, REENTER}

    ERC20Like public currency;

    uint256 public flashBalance;
    uint256 public flashValue;
    uint256 public flashFee;
    address public flashUser;

    constructor(ERC20Like currency_) {
        currency = currency_;
    }

    receive() external payable {}

    function onFlashLoan(address user, address token, uint256 value, uint256 fee, bytes calldata data) external {
        require(token == address(currency), "FlashBorrower: unsupported currency");
        (Action action) = abi.decode(data, (Action)); // Use this to unpack arbitrary data
        flashUser = user;
        flashValue = value;
        flashFee = fee;
        if (action == Action.NORMAL) {
            flashBalance = currency.balanceOf(address(this));
            currency.transfer(msg.sender, value + fee); // Resolve the flash loan
        } else if (action == Action.STEAL) {
            // Do nothing
        } else if (action == Action.REENTER) {
            flashBorrow(msg.sender, value * 2);
            currency.transfer(msg.sender, value + fee);
        }
    }

    function flashBorrow(address lender, uint256 value) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.NORMAL);
        FlashLenderLike(lender).flashLoan(address(this), address(currency), value, data);
    }

    function flashBorrowAndSteal(address lender, uint256 value) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.STEAL);
        FlashLenderLike(lender).flashLoan(address(this), address(currency), value, data);
    }

    function flashBorrowAndReenter(address lender, uint256 value) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.REENTER);
        FlashLenderLike(lender).flashLoan(address(this), address(currency), value, data);
    }
}
