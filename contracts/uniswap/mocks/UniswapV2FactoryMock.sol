// SPDX-License-Identifier: GPL-3.0-or-later
// Derived from https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Factory.sol

pragma solidity ^0.7.5;

import "../interfaces/UniswapV2FactoryLike.sol";
import "../interfaces/UniswapV2PairLike.sol";
import "./UniswapV2PairMock.sol";

contract UniswapV2FactoryMock is UniswapV2FactoryLike {

    mapping(address => mapping(address => address)) public override getPair;

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "UniswapV2: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(UniswapV2PairMock).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        UniswapV2PairLike(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
    }
}