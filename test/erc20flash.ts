const ERC20FlashLoan = artifacts.require('ERC20FlashLoan')
const ERC20FlashMint = artifacts.require('ERC20FlashMint')

// @ts-ignore
import { expectRevert } from '@openzeppelin/test-helpers'

type Contract = any

contract('ERC20FlashMint', async (accounts: string[]) => {
  let [owner, user] = accounts

  let token: Contract
  let name: string

  beforeEach(async () => {
    token = await ERC20FlashMint.new("Test", "TST", 1000, { from: owner })
  })

  it('tests to be added', async () => {
  })
})
