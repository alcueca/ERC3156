// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

import "../libraries/AaveDataTypes.sol";

interface LendingPoolLike {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function getReserveData(address asset) external view returns (AaveDataTypes.ReserveData memory);
}