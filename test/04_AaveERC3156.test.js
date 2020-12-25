const AToken = artifacts.require('ATokenMock')
const ERC20Currency = artifacts.require('ERC20Mock')
const LendingPoolAddressesProvider = artifacts.require('LendingPoolAddressesProviderMock')
const LendingPool = artifacts.require('LendingPoolMock')
const AaveERC3156 = artifacts.require('AaveERC3156')
const FlashBorrower = artifacts.require('FlashBorrower')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

const MAX = '115792089237316195423570985008687907853269984665640564039457584007913129639935'

contract('AaveERC3156', (accounts) => {
  const [deployer, user1] = accounts
  let currency1, currency2, aToken1, aToken2, lendingPool, lendingPoolAddressProvider, lender
  let borrower

  beforeEach(async () => {
    currency1 = await ERC20Currency.new("Test1", "TST1", { from: deployer })
    currency2 = await ERC20Currency.new("Test2", "TST2", { from: deployer })
    aToken1 = await AToken.new(currency1.address, "AToken1", "ATST1", { from: deployer })
    aToken2 = await AToken.new(currency2.address, "Atoken2", "ATST2", { from: deployer })
    lendingPool = await LendingPool.new({ from: deployer })
    await lendingPool.addReserve(aToken1.address, { from: deployer })
    await lendingPool.addReserve(aToken2.address, { from: deployer })
    lendingPoolAddressProvider = await LendingPoolAddressesProvider.new(lendingPool.address, { from: deployer })
    lender = await AaveERC3156.new(lendingPoolAddressProvider.address, { from: deployer })

    borrower = await FlashBorrower.new(currency1.address, { from: deployer })

    await currency1.mint(aToken1.address, 10000, { from: deployer })
    await currency2.mint(aToken2.address, 9999, { from: deployer })
  })

  it('should do a simple flash loan', async () => {
    await borrower.flashBorrow(lender.address, 1, { from: user1 })

    let balanceAfter = await currency1.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    let flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    let flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    let flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(borrower.address)
  })

  it('should do a loan that pays fees', async () => {
    await currency1.mint(borrower.address, 9, { from: user1 })
    await borrower.flashBorrow(lender.address, 10000, { from: user1 })

    const balanceAfter = await currency1.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(new BN('10009').toString())
    const flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(new BN('10000').toString())
    const flashFee = await borrower.flashFee()
    flashFee.toString().should.equal(new BN('9').toString())
    const flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(borrower.address)
  })

  /*
  it('should do a simple flash loan from an EOA', async () => {
    await lender.flashLoan(borrower.address, currency1.address, 1, '0x0000000000000000000000000000000000000000000000000000000000000000', { from: user1 })

    const balanceAfter = await currency1.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    const flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    const flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(user1)
  })

  it('needs to return funds after a flash loan', async () => {
    await expectRevert(
      borrower.flashBorrowAndSteal(lender.address, 1, { from: deployer }),
      'FlashLender: unpaid loan'
    )
  })

  it('should do two nested flash loans', async () => {
    await borrower.flashBorrowAndReenter(lender.address, 1, { from: deployer })

    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal('3')
  })
  */
})
