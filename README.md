# ERC20 Flash

This project is the reference implementation the [ERC 3156 Flash Loan](https://github.com/ethereum/EIPs/pull/3156) standard.

This project also implements ERC-3156 wrappers for the flash loan functionality of dYdX, Aave, Uniswap and Yield.

# Contracts deployed

## Kovan

Alternatively, you can use FlashBorrower to kick the tires. You can give to the `flashBorrow` function the address of an ERC3156 compliant lender (such as any of the wrappers in this repo), the address of a supported ERC20 token (which for wrappers depends on the underlying lender such as Aave) and a loan value. Upon execution a flash loan will happen, which you can examine in etherscan.io or tenderly.co. You will need to have transferred to FlashBorrower enough of the ERC20 being borrowed beforehand to pay for the fees.


| Contract      | Address       |
| ------------- |-------------- |
| FlashBorrower | 0xeeb0c120bF35fB0793b1c7d0D93230e552020398 |
| ERC20FlashMinter | 0x1e198e90c7166f7f9fD24b9D7A0451D7AeE78a3F |
| FlashLender | 0xC79bF13a7199867E6349287e90Ed76D645399705 |
| AaveERC3156 | 0x14df3b76309c91f3e8FA8Bc11bbc558f631E2594 |
| DYDXERC3156 | 0xC65151C0777614da245393b4481e29c885Da7C4D |
| UniswapERC3156 | 0xeBe2432d4b8C59F33674F6076ddeE8643B8039d1 |
| YieldDaiERC3156 | 0xDcD8a5C2cD166f90196205b2f76f273fd31684B4 |
| YieldFYDaiERC3156 | 0x9a8b26c62E05e6a8b472e1f01f2d09042Dd2093E |


### Tested currencies
The flash loans have been tested with the ERC20 tokens below, but should work for any tokens that the underlying lenders make available.

| Contract      | Address       |
| -------------------------- |-------------------- |
| ERC20FlashMinter (ERC20FlashMinter) | 0x1e198e90c7166f7f9fD24b9D7A0451D7AeE78a3F |
| WETH9 (FlashLender, AaveERC3156, DYDXERC3156, UniswapERC3156) | 0xd0A1E359811322d97991E03f863a0C30C2cF029C |
| DAI (FlashLender, YieldDaiERC3156, UniswapERC3156) | 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa |
| DAI (DYDXERC3156) | 0xC4375B7De8af5a38a93548eb8453a498222C4fF2 |
| DAI (AaveERC3156) | 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD |
| FYDAI (YieldFYDaiERC3156) | 0x6B166d6325586c86B44f01509Fc64e649DCfE7C4, 0x42AA68930d4430E2416036966983E6c9Fe8Ff2f8, 0x2b67866649AFcEFC63870E02EdefC318fd8760D3, 0x02B06417A3e3CB391970C6074AbcF2745a60b880, 0x6Abb65246346b2A52Faed338cB18880e70A57Cf8 |


### Sample Execution
Let's say you want to flash loan 10 DAI from dYdX via this wrapper.
1. Head to the [Flash Borrower contract](https://kovan.etherscan.io/address/0xeeb0c120bF35fB0793b1c7d0D93230e552020398#writeContract)
2. Connect via Web3 and expand '1. flashBorrow'
3. Input the following:
```
  lender: 0xC65151C0777614da245393b4481e29c885Da7C4D
  token: 0xC4375B7De8af5a38a93548eb8453a498222C4fF2
  value: 10000000000000000000
```
4. Then click Write to execute.
5. If all went well it should look [like this](https://kovan.etherscan.io/tx/0x96537d53089cd63e4b732cea796f1f65ed46383a307a2dd4a86c25c63c3893bf).


### Things to note
Flash loan basics still apply under this wrapper i.e.:
- If you're flashing 100 DAI @ 9bps/flash, make sure there's at least 100 + 0.09 DAI on the contract by the end of the transaction
- Native flash fees as at 31st Dec 2020 are: Aave 9bps, Uniswap 30 bps, dYdX 2 Wei, Yield 2.5 bps (time variant)
- Flash lenders generally have significantly reduced liquidity on kovan testnet, so if your tx is reverting, check whether you're requesting an amount higher than their respective testnet reserves
- Different protocols use different versions of the same token on kovan testnet, so make sure you pick the right one from above based on lender. This isn't an issue on mainnet.
