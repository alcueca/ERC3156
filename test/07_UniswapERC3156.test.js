const ERC20Currency = artifacts.require('ERC20Mock')
const UniswapV2Factory = artifacts.require('UniswapV2FactoryMock')
const UniswapV2Pair = artifacts.require('UniswapV2PairMock')
const UniswapERC3156 = artifacts.require('UniswapERC3156')
const FlashBorrower = artifacts.require('FlashBorrower')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()


contract('UniswapERC3156', (accounts) => {
  const [deployer, user1] = accounts
  let weth, dai, usdc, wethDaiPair, wethUsdcPair, uniswapFactory, lender
  let borrower
  const reserves = new BN(100000);

  beforeEach(async () => {
    weth = await ERC20Currency.new("WETH", "WETH")
    dai = await ERC20Currency.new("DAI", "DAI")
    usdc = await ERC20Currency.new("USDC", "USDC")

    uniswapFactory = await UniswapV2Factory.new({ from: deployer })

    // First we do a .call to retrieve the pair address, which is deterministic because of create2. Then we create the pair.
    wethDaiPairAddress = await uniswapFactory.createPair.call(weth.address, dai.address)
    await uniswapFactory.createPair(weth.address, dai.address)
    wethDaiPair = await UniswapV2Pair.at(wethDaiPairAddress)

    wethUsdcPairAddress = await uniswapFactory.createPair.call(weth.address, usdc.address)
    await uniswapFactory.createPair(weth.address, usdc.address)
    wethUsdcPair = await UniswapV2Pair.at(wethUsdcPairAddress)
    
    lender = await UniswapERC3156.new(uniswapFactory.address, weth.address, dai.address)

    borrower = await FlashBorrower.new()

    await weth.mint(wethDaiPair.address, reserves)
    await dai.mint(wethDaiPair.address, reserves)
    await wethDaiPair.mint({ from: deployer })

    await weth.mint(wethUsdcPair.address, reserves)
    await usdc.mint(wethUsdcPair.address, reserves)
    await wethUsdcPair.mint({ from: deployer })
  })

  it('flash supply', async function () {
    expect(await lender.maxFlashAmount(weth.address)).to.be.bignumber.equal(reserves.subn(1));
    expect(await lender.maxFlashAmount(dai.address)).to.be.bignumber.equal(reserves.subn(1));
    expect(await lender.maxFlashAmount(lender.address)).to.be.bignumber.equal("0");
  });

  it('flash fee', async function () {
    expect(await lender.flashFee(weth.address, reserves)).to.be.bignumber.equal(reserves.muln(3).divn(997).addn(1));
    expect(await lender.flashFee(dai.address, reserves)).to.be.bignumber.equal(reserves.muln(3).divn(997).addn(1));
    await expectRevert(
      lender.flashFee(lender.address, reserves),
      "Unsupported currency"
    )
  });

  it('weth flash loan', async () => {
    const loan = await lender.maxFlashAmount(weth.address)
    const fee = await lender.flashFee(weth.address, loan)
    await weth.mint(borrower.address, fee, { from: user1 })
    await borrower.flashBorrow(lender.address, weth.address, loan, { from: user1 })

    const balanceAfter = await weth.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(loan.add(fee).toString())
    const flashAmount = await borrower.flashAmount()
    flashAmount.toString().should.equal(loan.toString())
    const flashFee = await borrower.flashFee()
    flashFee.toString().should.equal(fee.toString())
    const flashSender = await borrower.flashSender()
    flashSender.toString().should.equal(borrower.address)
  })

  it('dai flash loan', async () => {
    const loan = await lender.maxFlashAmount(dai.address)
    const fee = await lender.flashFee(dai.address, loan)
    await dai.mint(borrower.address, fee, { from: user1 })
    await borrower.flashBorrow(lender.address, dai.address, loan, { from: user1 })

    const balanceAfter = await dai.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(loan.add(fee).toString())
    const flashAmount = await borrower.flashAmount()
    flashAmount.toString().should.equal(loan.toString())
    const flashFee = await borrower.flashFee()
    flashFee.toString().should.equal(fee.toString())
    const flashSender = await borrower.flashSender()
    flashSender.toString().should.equal(borrower.address)
  })
})
