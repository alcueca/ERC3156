const Pool = artifacts.require('Pool')
const FYDaiMock = artifacts.require('FYDaiMock')
const ERC20Mock = artifacts.require('ERC20Mock')
const YieldDaiERC3156 = artifacts.require('YieldDaiERC3156')
const FlashBorrower = artifacts.require('FlashBorrower')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()


contract('YieldDaiERC3156', async (accounts) => {
  let [deployer, user1] = accounts

  const pooledDai = "1000000000000000000"
  const pooledFYDai = "300000000000000000"

  let dai
  let pool
  let fyDai
  let lender
  let borrower

  let maturity0

  beforeEach(async () => {

    // Setup fyDai
    const block = await web3.eth.getBlockNumber()
    maturity0 = (await web3.eth.getBlock(block)).timestamp + 15778476 // Six months

    dai = await ERC20Mock.new("Test", "TST")
    fyDai = await FYDaiMock.new("Test", "TST", maturity0)

    // Setup Pools
    pool = await Pool.new(dai.address, fyDai.address, 'Name', 'Symbol')

    // Initialize pools
    await dai.mint(user1, pooledDai, { from: user1 })
    await dai.approve(pool.address, pooledDai, { from: user1 })
    await pool.mint(user1, user1, pooledDai, { from: user1 })
    await fyDai.mint(pool.address, pooledFYDai)

    // Set up the ERC3156 wrapper
    lender = await YieldDaiERC3156.new(pool.address)

    // Set up the borrrower
    borrower = await FlashBorrower.new()
  })

  it('flash supply', async function () {
    expect(await lender.flashSupply(dai.address)).to.be.bignumber.equal(await dai.balanceOf(pool.address));
    expect(await lender.flashSupply(lender.address)).to.be.bignumber.equal("0");
  });

  it('flash fee', async function () {
    const loan = new BN("1000000000000000000")
    expect(await lender.flashFee(dai.address, loan)).to.be.bignumber.gt("0");
    await expectRevert(
      lender.flashFee(lender.address, loan),
      "Unsupported currency"
    )
  });

  it('should do a simple flash loan', async () => {
    const ONE = new BN("1000000000000000000")
    const loan = ONE

    const expectedFee = await lender.flashFee(dai.address, loan)

    await dai.mint(user1, ONE, { from: user1 })
    await dai.transfer(borrower.address, ONE, { from: user1 })

    const balanceBefore = await dai.balanceOf(borrower.address)
    await borrower.flashBorrow(lender.address, dai.address, loan, { from: user1 })

    assert.equal(await borrower.flashUser(), borrower.address)
    assert.equal((await borrower.flashValue()).toString(), loan.toString())
    assert.equal((await borrower.flashBalance()).toString(), balanceBefore.add(loan).toString())

    const fee = await borrower.flashFee()
    assert.equal((await dai.balanceOf(borrower.address)).toString(), balanceBefore.sub(fee).toString())
    // almostEqual(fee.toString(), expectedFee.toString(), fee.div(new BN('100000')).toString()) // Accurate to 0.00001 %
  })
})
