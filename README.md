# ERC20 Flash

This project is the reference implementation the the [ERC 3156 Flash Loan](https://github.com/ethereum/EIPs/pull/3156) standard.

The contracts included inherit from OpenZeppelin's ERC20.

## How to Use

`ERC20FlashLoan` and `ERC20FlashMint` are `ERC20` contracts. You can just inherit from them and you are done from the smart contracts point of view.

```
contract MyContract is ERC20FlashMint {

    constructor (string memory _name, string memory _symbol, uint256 _fee) public ERC20FlashMint(_name, _symbol, _fee) {...}

    ...
}
```

```
contract MyContract is ERC20FlashLoan {

    constructor (string memory _name, string memory _symbol, IERC20 _asset, uint256 _fee) public ERC20FlashLoan(_name, _symbol, _asset, _fee) {...}

    ...
}
```

The `_fee` parameter is a divisor to be applied on the flash loaned values. The `receiver` of the `flashLoan` will have to pay back `value + value/fee`.