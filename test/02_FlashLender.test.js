const FlashLender = artifacts.require('FlashLender')
const ERC20Currency = artifacts.require('ERC20Mock')
const FlashBorrower = artifacts.require('FlashBorrower')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

const MAX = '115792089237316195423570985008687907853269984665640564039457584007913129639935'

contract('FlashLender', (accounts) => {
  const [deployer, user1] = accounts
  let weth, dai
  let lender
  let borrower

  beforeEach(async () => {
    weth = await ERC20Currency.new("WETH", "WETH")
    dai = await ERC20Currency.new("DAI", "DAI")
    lender = await FlashLender.new([weth.address, dai.address], 1000)
    borrower = await FlashBorrower.new()

    await weth.mint(lender.address, 1000)
    await dai.mint(lender.address, 999)
  })

  it('should do a simple flash loan', async () => {
    await borrower.flashBorrow(lender.address, weth.address, 1, { from: user1 })

    let balanceAfter = await weth.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    let flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    let flashToken = await borrower.flashToken()
    flashToken.toString().should.equal(weth.address)
    let flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    let flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(borrower.address)

    await borrower.flashBorrow(lender.address, dai.address, 3, { from: user1 })

    balanceAfter = await dai.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(new BN('3').toString())
    flashToken = await borrower.flashToken()
    flashToken.toString().should.equal(dai.address)
    flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(new BN('3').toString())
    flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(borrower.address)
  })

  it('should do a loan that pays fees', async () => {
    await weth.mint(borrower.address, 1, { from: user1 })
    await borrower.flashBorrow(lender.address, weth.address, 1000, { from: user1 })

    const balanceAfter = await weth.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(new BN('1001').toString())
    const flashToken = await borrower.flashToken()
    flashToken.toString().should.equal(weth.address)
    const flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(new BN('1000').toString())
    const flashFee = await borrower.flashFee()
    flashFee.toString().should.equal(new BN('1').toString())
    const flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(borrower.address)
  })

  it('lenders can choose to charge no fees', async () => {
    lender = await FlashLender.new([weth.address, dai.address], MAX)
    await weth.mint(lender.address, 1000)

    await borrower.flashBorrow(lender.address, weth.address, 1000, { from: user1 })

    const balanceAfter = await weth.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(new BN('1000').toString())
    const flashToken = await borrower.flashToken()
    flashToken.toString().should.equal(weth.address)
    const flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(new BN('1000').toString())
    const flashFee = await borrower.flashFee()
    flashFee.toString().should.equal(new BN('0').toString())
    const flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(borrower.address)
  })

  it('should do a simple flash loan from an EOA', async () => {
    await lender.flashLoan(borrower.address, weth.address, 1, '0x0000000000000000000000000000000000000000000000000000000000000000', { from: user1 })

    const balanceAfter = await weth.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    const flashToken = await borrower.flashToken()
    flashToken.toString().should.equal(weth.address)
    const flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    const flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(user1)
  })

  it('needs to return funds after a flash loan', async () => {
    await expectRevert(
      borrower.flashBorrowAndSteal(lender.address, weth.address, 1),
      'FlashLender: unpaid loan'
    )
  })

  it('should do two nested flash loans', async () => {
    await borrower.flashBorrowAndReenter(lender.address, weth.address, 1)

    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal('3')
  })
})
