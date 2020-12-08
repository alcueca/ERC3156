const FlashLender = artifacts.require('FlashLender')
const ERC20Currency = artifacts.require('ERC20Mock')
const FlashBorrower = artifacts.require('FlashBorrower')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

const MAX = '115792089237316195423570985008687907853269984665640564039457584007913129639935'

contract('FlashLender', (accounts) => {
  const [deployer, user1] = accounts
  let currency
  let lender
  let borrower

  beforeEach(async () => {
    currency = await ERC20Currency.new("Test", "TST", { from: deployer })
    lender = await FlashLender.new(currency.address, 1000, { from: deployer })
    borrower = await FlashBorrower.new(currency.address, { from: deployer })

    await currency.mint(lender.address, 1000, { from: deployer })
  })

  it('should do a simple flash loan', async () => {
    await borrower.flashBorrow(lender.address, 1, { from: user1 })

    const balanceAfter = await currency.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    const flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    const flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(borrower.address)
  })

  it('should do a loan that pays fees', async () => {
    await currency.mint(borrower.address, 1, { from: user1 })
    await borrower.flashBorrow(lender.address, 1000, { from: user1 })

    const balanceAfter = await currency.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(new BN('1001').toString())
    const flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(new BN('1000').toString())
    const flashFee = await borrower.flashFee()
    flashFee.toString().should.equal(new BN('1').toString())
    const flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(borrower.address)
  })


  it('lenders can choose to charge no fees', async () => {
    lender = await FlashLender.new(currency.address, MAX, { from: deployer })
    await currency.mint(lender.address, 1000, { from: deployer })

    await borrower.flashBorrow(lender.address, 1000, { from: user1 })

    const balanceAfter = await currency.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(new BN('1000').toString())
    const flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(new BN('1000').toString())
    const flashFee = await borrower.flashFee()
    flashFee.toString().should.equal(new BN('0').toString())
    const flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(borrower.address)
  })

  it('should do a simple flash loan from an EOA', async () => {
    await lender.flashLoan(borrower.address, 1, '0x0000000000000000000000000000000000000000000000000000000000000000', { from: user1 })

    const balanceAfter = await currency.balanceOf(user1)
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
})
