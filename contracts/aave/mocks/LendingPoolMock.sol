// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/LendingPoolAddressesProviderLike.sol";
import "../libraries/AaveDataTypes.sol";


interface FlashLoanReceiverLike {
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);
}

interface ATokenLike {
    function underlying() external view returns (address);
    function transferUnderlyingTo(address, uint256) external;
}

contract LendingPoolStorage {
  mapping(address => AaveDataTypes.ReserveData) internal _reserves;

  // the list of the available reserves, structured as a mapping for gas savings reasons
  mapping(uint256 => address) internal _reservesList;

  uint256 internal _reservesCount;
}

/**
 * @title LendingPoolMock contract
 * @dev Main point of interaction with an Aave protocol's market
 * - Users can:
 *   # Execute Flash Loans
 **/
contract LendingPoolMock is LendingPoolStorage {
  using SafeMath for uint256;

  //main configuration parameters
  uint256 public constant FLASHLOAN_PREMIUM_TOTAL = 9;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the FlashLoanReceiverLike interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata,         // modes
    address,                    // onBehalfOf
    bytes calldata params,
    uint16                      // referralCode
  ) external {
    // In this mock we will execute only the flash loan in position 0 of the arrays
    uint256[] memory premiums = new uint256[](assets.length);
    premiums[0] = amounts[0].mul(FLASHLOAN_PREMIUM_TOTAL).div(10000);

    address aTokenAddress = _reserves[assets[0]].aTokenAddress;
    ATokenLike(aTokenAddress).transferUnderlyingTo(receiverAddress, amounts[0]);

    require(
      FlashLoanReceiverLike(receiverAddress).executeOperation(assets, amounts, premiums, msg.sender, params),
      "Invalid flash loan return"
    );

    IERC20(assets[0]).transferFrom(
        receiverAddress,
        aTokenAddress,
        amounts[0].add(premiums[0])
    );
  }

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset)
    external view returns (AaveDataTypes.ReserveData memory)
  {
    return _reserves[asset];
  }

  /**
   * @dev Returns the list of the initialized reserves
   **/
  function getReservesList()
    external view returns (address[] memory)
  {
    address[] memory _activeReserves = new address[](_reservesCount);

    for (uint256 i = 0; i < _reservesCount; i++) {
      _activeReserves[i] = _reservesList[i];
    }
    return _activeReserves;
  }

  /**
   * @dev Adds a reserve to the reserves list, as an ATokenMock and underlying ERC20Mock pair
   * @param asset The address of the underlying asset of the reserve
   **/
  function addReserve(address asset)
    external
  {
    uint256 reservesCount = _reservesCount;
    _reserves[asset].id = uint8(reservesCount);
    _reserves[asset].aTokenAddress = ATokenLike(asset).underlying();
    _reservesList[reservesCount] = asset;
    _reservesCount = reservesCount + 1;
  }
}