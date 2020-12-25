const FlashLender = artifacts.require('FlashLender')
const ERC20Currency = artifacts.require('ERC20Mock')
const FlashBorrower = artifacts.require('FlashBorrower')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

const MAX = '115792089237316195423570985008687907853269984665640564039457584007913129639935'

contract('FlashLender', (accounts) => {
  const [deployer, user1] = accounts
  let currency1, currency2
  let lender
  let borrower1

  beforeEach(async () => {
    currency1 = await ERC20Currency.new("Test1", "TST1", { from: deployer })
    currency2 = await ERC20Currency.new("Test2", "TST2", { from: deployer })
    lender = await FlashLender.new(currency1.address, currency2.address, 1000, { from: deployer })
    borrower1 = await FlashBorrower.new(currency1.address, { from: deployer })
    borrower2 = await FlashBorrower.new(currency2.address, { from: deployer })

    await currency1.mint(lender.address, 1000, { from: deployer })
    await currency2.mint(lender.address, 999, { from: deployer })
  })

  it('should do a simple flash loan', async () => {
    await borrower1.flashBorrow(lender.address, 1, { from: user1 })

    let balanceAfter = await currency1.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    let flashBalance = await borrower1.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    let flashValue = await borrower1.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    let flashUser = await borrower1.flashUser()
    flashUser.toString().should.equal(borrower1.address)

    await borrower2.flashBorrow(lender.address, 3, { from: user1 })

    balanceAfter = await currency2.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    flashBalance = await borrower2.flashBalance()
    flashBalance.toString().should.equal(new BN('3').toString())
    flashValue = await borrower2.flashValue()
    flashValue.toString().should.equal(new BN('3').toString())
    flashUser = await borrower2.flashUser()
    flashUser.toString().should.equal(borrower2.address)
  })

  it('should do a loan that pays fees', async () => {
    await currency1.mint(borrower1.address, 1, { from: user1 })
    await borrower1.flashBorrow(lender.address, 1000, { from: user1 })

    const balanceAfter = await currency1.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower1.flashBalance()
    flashBalance.toString().should.equal(new BN('1001').toString())
    const flashValue = await borrower1.flashValue()
    flashValue.toString().should.equal(new BN('1000').toString())
    const flashFee = await borrower1.flashFee()
    flashFee.toString().should.equal(new BN('1').toString())
    const flashUser = await borrower1.flashUser()
    flashUser.toString().should.equal(borrower1.address)
  })

  it('lenders can choose to charge no fees', async () => {
    lender = await FlashLender.new(currency1.address, currency2.address, MAX, { from: deployer })
    await currency1.mint(lender.address, 1000, { from: deployer })

    await borrower1.flashBorrow(lender.address, 1000, { from: user1 })

    const balanceAfter = await currency1.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower1.flashBalance()
    flashBalance.toString().should.equal(new BN('1000').toString())
    const flashValue = await borrower1.flashValue()
    flashValue.toString().should.equal(new BN('1000').toString())
    const flashFee = await borrower1.flashFee()
    flashFee.toString().should.equal(new BN('0').toString())
    const flashUser = await borrower1.flashUser()
    flashUser.toString().should.equal(borrower1.address)
  })

  it('should do a simple flash loan from an EOA', async () => {
    await lender.flashLoan(borrower1.address, currency1.address, 1, '0x0000000000000000000000000000000000000000000000000000000000000000', { from: user1 })

    const balanceAfter = await currency1.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower1.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    const flashValue = await borrower1.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    const flashUser = await borrower1.flashUser()
    flashUser.toString().should.equal(user1)
  })

  it('needs to return funds after a flash loan', async () => {
    await expectRevert(
      borrower1.flashBorrowAndSteal(lender.address, 1, { from: deployer }),
      'FlashLender: unpaid loan'
    )
  })

  it('should do two nested flash loans', async () => {
    await borrower1.flashBorrowAndReenter(lender.address, 1, { from: deployer })

    const flashBalance = await borrower1.flashBalance()
    flashBalance.toString().should.equal('3')
  })
})
