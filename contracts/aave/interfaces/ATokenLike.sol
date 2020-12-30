// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;


interface ATokenLike {
    function underlying() external view returns (address);
    function transferUnderlyingTo(address, uint256) external;
}