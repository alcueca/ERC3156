# ERC20 Flash

This project is the reference implementation the [ERC 3156 Flash Loan](https://github.com/ethereum/EIPs/pull/3156) standard.

This project also implements ERC-3156 wrappers for the flash loan functionality of dYdX, Aave, Uniswap and Yield.

# Contracts deployed

## Kovan

In all real use cases, you will have to create your own contract to take flashLoans, calling the `flashLoan` function on an ERC3156 compliant lender (or one of the wrappers in this repo), and implementing the `onFlashLoan` callback.

However, you can use FlashBorrower to kick the tires. You can give to the `flashBorrow` function the address of an ERC3156 compliant lender (such as any of the wrappers in this repo), the address of a supported ERC20 token (which for wrappers depends on the underlying lender such as Aave) and a loan value. Upon execution a flash loan will happen, which you can examine in etherscan.io or tenderly.co. You will need to have transferred to FlashBorrower enough of the ERC20 being borrowed beforehand to pay for the fees.


| Lender Contract      | Lender Address       |
| ------------- |-------------- |
| FlashBorrower | 0x5e3538099b9d19Dc8EB13cb1AD2b0e93D2cC2EbB |
| FlashMinter | 0xC8df3958bb0D68e22e4d974CdA71d73A4e7E73b9 |
| FlashLender | 0xeef77EAE62e80F5F56b85Be318B57BF1470874F5 |
| AaveERC3156 | 0xC355Fb535757B069D84B3bB01c27240DF973FBa2 |
| DYDXERC3156 | 0xf1E70c817C82975Dfb6a0B7AB65b803f871E2c4E |
| UniswapERC3156 | 0x353939fcA37c1782512229d5D4f0d3E83Bf46B2C |
| YieldDaiERC3156 | 0x8E1ceabD0996bbDd15E611D26d333b8e9d684a27 |
| YieldFYDaiERC3156 | 0x2F01fa8f4377682018B74B696933528ba03f1eb0 |


### Tested currencies
The flash loans have been tested with the ERC20 tokens below, but should work for any tokens that the underlying lenders make available.

| Lender Contract      | Currency       |
| -------------------------- |-------------------- |
| FlashMinter | FlashMinter - 0x1e198e90c7166f7f9fD24b9D7A0451D7AeE78a3F |
| FlashLender, AaveERC3156, DYDXERC3156, UniswapERC3156 | WETH9 - 0xd0A1E359811322d97991E03f863a0C30C2cF029C |
| FlashLender, YieldDaiERC3156, UniswapERC3156 | DAI - 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa |
| DYDXERC3156 | DAI - 0xC4375B7De8af5a38a93548eb8453a498222C4fF2 |
| AaveERC3156 | DAI - 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD |
| YieldFYDaiERC3156 | FYDAI - 0x6B166d6325586c86B44f01509Fc64e649DCfE7C4, 0x42AA68930d4430E2416036966983E6c9Fe8Ff2f8, 0x2b67866649AFcEFC63870E02EdefC318fd8760D3, 0x02B06417A3e3CB391970C6074AbcF2745a60b880, 0x6Abb65246346b2A52Faed338cB18880e70A57Cf8 |


### Sample Execution
Let's say you want to test a flash loan of 10 DAI from Uniswap using `FlashBorrower` and the `UniswapERC3156` wrapper.
1. Head to the [Flash Borrower contract](https://kovan.etherscan.io/address/0xeeb0c120bF35fB0793b1c7d0D93230e552020398#writeContract)
2. Connect via Web3 and expand '1. flashBorrow'
3. Input the following:
```
  lender: 0xeBe2432d4b8C59F33674F6076ddeE8643B8039d1
  token: 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa
  value: 10000000000000000000
```
4. Then click Write to execute.
5. If all went well it should look [like this](https://kovan.etherscan.io/tx/0x87d4bb5713080eaf5543131893e8a8c496ad7bce78ddd06bdbf9bde9d3eaf1fd).

[Flash Borrower](https://kovan.etherscan.io/address/0xeeb0c120bF35fB0793b1c7d0D93230e552020398#writeContract) needs to have enough of the borrowed token to pay for the flash loan fees.
1. Check the fee amount with the [flashFee](https://kovan.etherscan.io/address/0xeBe2432d4b8C59F33674F6076ddeE8643B8039d1#readContract) function, the token is DAI (0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa).
2. Check the DAI balance of flashBorrower (0xeeb0c120bF35fB0793b1c7d0D93230e552020398) [balanceOf](https://kovan.etherscan.io/address/0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa#readContract) function of the DAI contract.
3. If FlashBorrower doesn't have enough DAI to pay for the loan fees, go to [Uniswap](https://app.uniswap.org/#/swap) and making sure that you are in Kovan, buy some DAI by address (0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa) and send it to the FlashBorrower (0xeeb0c120bF35fB0793b1c7d0D93230e552020398).

### Things to note
Flash loan basics still apply under this wrapper i.e.:
- If you're flashing 100 DAI @ 9bps/flash, make sure there's at least 100 + 0.09 DAI on the contract by the end of the transaction
- Native flash fees as at 31st Dec 2020 are: Aave 9bps, Uniswap 30 bps, dYdX 2 Wei, Yield 2.5 bps (time variant)
- Flash lenders generally have significantly reduced liquidity on kovan testnet, so if your tx is reverting, check whether you're requesting an amount higher than their respective testnet reserves
- Different protocols use different versions of the same token on kovan testnet, so make sure you pick the right one from above based on lender. This isn't an issue on mainnet.
