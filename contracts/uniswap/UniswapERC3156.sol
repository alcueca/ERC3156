pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC3156FlashBorrower, IERC3156FlashLender } from "../interfaces/IERC3156.sol";
import "./interfaces/UniswapV2PairLike.sol";
import "./interfaces/UniswapV2FactoryLike.sol";
import "./interfaces/UniswapFlashBorrowerLike.sol";


contract UniswapERC3156 is IERC3156FlashLender, UniswapFlashBorrowerLike {

    // CONSTANTS
    UniswapV2FactoryLike constant uniswapV2Factory = UniswapV2FactoryLike(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); // same for all networks

    // ACCESS CONTROL
    // Only the `permissionedPairAddress` may call the `uniswapV2Call` function
    address permissionedPairAddress;

    // DEFAULT TOKENS
    address WETH;
    address DAI;

    constructor(address _DAI, address _WETH) public {
        WETH = _WETH;
        DAI = _DAI;
    }

    function flashSupply(address token) external view override returns (uint256) {
        address tokenOther = token == WETH ? DAI : WETH;
        address pairAddress = uniswapV2Factory.getPair(token, tokenOther);
        return pairAddress != address(0) ? IERC20(token).balanceOf(pairAddress) : 0;
    }

    function flashFee(address token, uint256 amount) public view override returns (uint256) {
        address tokenOther = token == WETH ? DAI : WETH;
        address pairAddress = uniswapV2Factory.getPair(token, tokenOther);
        require(pairAddress != address(0), "Unsupported currency");

        return ((amount * 3) / 997) + 1;
    }

    // @notice This function is used when the user repays with the same token they borrowed
    // @dev This initiates the flash borrow. See `simpleFlashLoanExecute` for the code that executes after the borrow.
    function flashLoan(address receiver, address token, uint256 amount, bytes memory userData) external override {
        address tokenOther = token == WETH ? DAI : WETH;
        address pairAddress = uniswapV2Factory.getPair(token, tokenOther);
        require(pairAddress != address(0), "Requested token is not available.");

        if (permissionedPairAddress != pairAddress) permissionedPairAddress = pairAddress; // access control

        address token0 = UniswapV2PairLike(pairAddress).token0();
        address token1 = UniswapV2PairLike(pairAddress).token1();
        uint amount0Out = token == token0 ? amount : 0;
        uint amount1Out = token == token1 ? amount : 0;
        bytes memory data = abi.encode(
            msg.sender,
            receiver,
            token,
            userData
        );
        UniswapV2PairLike(pairAddress).swap(amount0Out, amount1Out, address(this), data);
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

        // do whatever the user wants
        IERC3156FlashBorrower(receiver).onFlashLoan(origin, token, amount, fee, userData);

        IERC20(token).transfer(msg.sender, amountToRepay);
    }
}