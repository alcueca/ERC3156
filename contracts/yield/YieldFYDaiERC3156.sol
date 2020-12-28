// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.5;

import "./interfaces/IFYDai.sol";
import "./interfaces/YieldFlashBorrowerLike.sol";
import { IERC3156FlashBorrower, IERC3156FlashLender } from "../interfaces/IERC3156.sol";


/**
 * YieldFYDaiLender allows flash loans of fyDai compliant with ERC-3156: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-3156.md
 */
contract YieldFYDaiERC3156 is IERC3156FlashLender, YieldFlashBorrowerLike {

    mapping(address => bool) public tokensRegistered;

    constructor (address[] memory fyDais) {
        for (uint256 i = 0; i < fyDais.length; i++) {
            tokensRegistered[fyDais[i]] = true;
        }
    }

    /// @dev Fee charged on top of a fyDai flash loan.
    function flashFee(address token, uint256) public view override returns (uint256) {
        require(tokensRegistered[token], "Unsupported currency");
        return 0;
    }

    /// @dev Maximum fyDai flash loan available.
    function flashSupply(address token) public view override returns (uint256) {
        return tokensRegistered[token] ? type(uint112).max - IFYDai(token).totalSupply() : 0;
    }

    /// @dev ERC-3156 entry point to send `fyDaiAmount` fyDai to `receiver` as a flash loan.
    function flashLoan(address receiver, address fyDai, uint256 fyDaiAmount, bytes memory userData) public override {
        bytes memory data = abi.encode(msg.sender, receiver, userData);
        IFYDai(fyDai).flashMint(fyDaiAmount, data);
    }

    /// @dev FYDai `flashMint` callback, which bridges to the ERC-3156 `onFlashLoan` callback.
    function executeOnFlashMint(uint256 fyDaiAmount, bytes memory data) public override {
        (address origin, address receiver, bytes memory userData) = abi.decode(data, (address, address, bytes));
        IFYDai(msg.sender).transfer(receiver, fyDaiAmount);
        IERC3156FlashBorrower(receiver).onFlashLoan(origin, msg.sender, fyDaiAmount, 0, userData); // msg.sender is the lending fyDai contract
    }
}
