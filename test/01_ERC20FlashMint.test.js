const ERC20FlashMinter = artifacts.require('ERC20FlashMinterMock')
const FlashBorrower = artifacts.require('FlashBorrower')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

const MAX = '115792089237316195423570985008687907853269984665640564039457584007913129639935'

contract('ERC20FlashMinter', (accounts) => {
  const [deployer, user1] = accounts
  let lender
  let borrower

  beforeEach(async () => {
    lender = await ERC20FlashMinter.new("Test", "TST", 1000, { from: deployer })
    borrower = await FlashBorrower.new(lender.address, { from: deployer })
  })

  it('should do a simple flash loan', async () => {
    await borrower.flashBorrow(lender.address, 1, { from: user1 })

    const balanceAfter = await lender.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    const flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    const flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(borrower.address)
  })

  it('should do a loan that pays fees', async () => {
    await lender.mint(borrower.address, 1, { from: user1 })
    await borrower.flashBorrow(lender.address, 1000, { from: user1 })

    const balanceAfter = await lender.balanceOf(user1)
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
    lender = await ERC20FlashMinter.new("Test", "TST", MAX, { from: deployer })
    borrower = await FlashBorrower.new(lender.address, { from: deployer })

    await borrower.flashBorrow(lender.address, 1000, { from: user1 })

    const balanceAfter = await lender.balanceOf(user1)
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
    await lender.flashLoan(borrower.address, lender.address, 1, '0x0000000000000000000000000000000000000000000000000000000000000000', { from: user1 })

    const balanceAfter = await lender.balanceOf(user1)
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
      'ERC20: burn amount exceeds balance'
    )
  })

  it('should do two nested flash loans', async () => {
    await borrower.flashBorrowAndReenter(lender.address, 1, { from: deployer })

    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal('3')
  })
})
