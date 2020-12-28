// SPDX-License-Identifier: GPL-3.0-or-later
// Derived from https://github.com/Austin-Williams/uniswap-flash-swapper

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC3156FlashBorrower, IERC3156FlashLender } from "../interfaces/IERC3156.sol";
import "./interfaces/UniswapV2PairLike.sol";
import "./interfaces/UniswapV2FactoryLike.sol";
import "./interfaces/UniswapV2FlashBorrowerLike.sol";


contract UniswapERC3156 is IERC3156FlashLender, UniswapV2FlashBorrowerLike {
    // CONSTANTS
    UniswapV2FactoryLike public factory;

    // ACCESS CONTROL
    // Only the `permissionedPairAddress` may call the `uniswapV2Call` function
    address permissionedPairAddress;

    // DEFAULT TOKENS
    address weth;
    address dai;

    constructor(UniswapV2FactoryLike factory_, address weth_, address dai_) {
        factory = factory_;
        weth = weth_;
        dai = dai_;
    }

    function getPairAddress(address token) public view returns (address) {
        address tokenOther = token == weth ? dai : weth;
        return factory.getPair(token, tokenOther);
    }

    function flashSupply(address token) external view override returns (uint256) {
        address pairAddress = getPairAddress(token);
        if (pairAddress != address(0)) {
            uint256 balance = IERC20(token).balanceOf(pairAddress);
            if (balance > 0) return balance - 1;
        }
        return 0;
    }

    function flashFee(address token, uint256 amount) public view override returns (uint256) {
        require(getPairAddress(token) != address(0), "Unsupported currency");
        return ((amount * 3) / 997) + 1;
    }

    function flashLoan(address receiver, address token, uint256 amount, bytes memory userData) external override {
        address pairAddress = getPairAddress(token);
        require(pairAddress != address(0), "Unsupported currency");

        UniswapV2PairLike pair = UniswapV2PairLike(pairAddress);

        if (permissionedPairAddress != pairAddress) permissionedPairAddress = pairAddress; // access control

        address token0 = pair.token0();
        address token1 = pair.token1();
        uint amount0Out = token == token0 ? amount : 0;
        uint amount1Out = token == token1 ? amount : 0;
        bytes memory data = abi.encode(
            msg.sender,
            receiver,
            token,
            userData
        );
        pair.swap(amount0Out, amount1Out, address(this), data);
    }

    // @notice Function is called by the Uniswap V2 pair's `swap` function
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        // access control
        require(msg.sender == permissionedPairAddress, "only permissioned UniswapV2 pair can call");
        require(sender == address(this), "only this contract may initiate");

        uint amount = amount0 > 0 ? amount0 : amount1;

        // decode data
        (
            address origin,
            address receiver,
            address token,
            bytes memory userData
        ) = abi.decode(data, (address, address, address, bytes));

        // compute amount of tokens that need to be paid back
        uint fee = ((amount * 3) / 997) + 1;
        uint amountToRepay = amount + fee;
        
        // send the borrowed amount to the receiver
        IERC20(token).transfer(receiver, amount);
        // do whatever the user wants
        IERC3156FlashBorrower(receiver).onFlashLoan(origin, token, amount, fee, userData);

        IERC20(token).transfer(msg.sender, amountToRepay);
    }
}