# ERC20 Flash

This project is the reference implementation the the [ERC 3156 Flash Loan](https://github.com/ethereum/EIPs/pull/3156) standard.

The contracts included inherit from OpenZeppelin's ERC20.

## How to Use

`ERC20FlashMinter` is an `ERC20` contract with flash minting capabilities.

```
contract MyContract is ERC20FlashMinter {

    constructor (string memory _name, string memory _symbol, uint256 _fee) public ERC20FlashMinter(_name, _symbol, _fee) {...}

    ...
}
```

`FlashLender` uses an `ERC20` contract as currency and has flash lending capabilities.

```
contract MyContract is ERC20FlashLoan {

    constructor (string memory _name, string memory _symbol, IERC20 _asset, uint256 _fee) public ERC20FlashLoan(_name, _symbol, _asset, _fee) {...}

    ...
}
```

The `_fee` parameter is a divisor to be applied on the flash loaned values. The `receiver` of the `flashLoan` will have to pay back `value + value/fee`. Set the `_fee` to 2 ** 256 - 1 (type(uint256).max) to charge no fees.