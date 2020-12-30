// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;


interface YieldFlashBorrowerLike {
    function executeOnFlashMint(uint256 fyDaiAmount, bytes memory data) external;
}