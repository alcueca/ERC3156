// SPDX-License-Identifier: GPL-3.0-or-later
// Derived from https://github.com/yieldprotocol/fyDai-flash
pragma solidity ^0.7.5;

import "./interfaces/IFYDai.sol";
import "./interfaces/YieldFlashBorrowerLike.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "../interfaces/IERC3156FlashLender.sol";


/**
 * YieldFYDaiLender allows flash loans of fyDai compliant with ERC-3156: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-3156.md
 */
contract YieldFYDaiERC3156 is IERC3156FlashLender, YieldFlashBorrowerLike {

    mapping(address => bool) public fyDaisSupported;

    /// @param fyDais List of Yield FYDai contracts that will be supported for flash lending.
    constructor (address[] memory fyDais) {
        for (uint256 i = 0; i < fyDais.length; i++) {
            fyDaisSupported[fyDais[i]] = true;
        }
    }

    /**
     * @dev From ERC-3156. The amount of currency available to be lended.
     * @param token The loan currency. It must be a FYDai contract.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashAmount(address token) public view override returns (uint256) {
        return fyDaisSupported[token] ? type(uint112).max - IFYDai(token).totalSupply() : 0;
    }

    /**
     * @dev From ERC-3156. The fee to be charged for a given loan.
     * @param token The loan currency. It must be a FYDai.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) public view override returns (uint256) {
        require(fyDaisSupported[token], "Unsupported currency");
        return 0;
    }

    /**
     * @dev From ERC-3156. Loan `amount` fyDai to `receiver`, which needs to return them plus fee to this contract within the same transaction.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency. Must be a fyDai contract.
     * @param amount The amount of tokens lent.
     * @param userData A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes memory userData) public override {
        bytes memory data = abi.encode(msg.sender, receiver, userData);
        IFYDai(token).flashMint(amount, data);
    }

    /// @dev FYDai flash loan callback. It sends the value borrowed to `receiver`, and takes the value back after the callback.
    function executeOnFlashMint(uint256 amount, bytes memory data) public override {
        (address origin, IERC3156FlashBorrower receiver, bytes memory userData) = 
            abi.decode(data, (address, IERC3156FlashBorrower, bytes));
        IFYDai(msg.sender).transfer(address(receiver), amount);
        receiver.onFlashLoan(origin, msg.sender, amount, 0, userData); // msg.sender is the lending fyDai contract
        IFYDai(msg.sender).transferFrom(address(receiver), address(this), amount);
        IFYDai(msg.sender).approve(msg.sender, amount);
    }
}
