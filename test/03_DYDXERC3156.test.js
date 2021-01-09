const SoloMarginMock = artifacts.require('SoloMarginMock');
const DYDXERC3156 = artifacts.require('DYDXERC3156');
const ERC20Mock = artifacts.require('ERC20Mock');
const FlashBorrower = artifacts.require('FlashBorrower');

const { BN, expectRevert } = require('@openzeppelin/test-helpers');
require('chai').use(require('chai-as-promised')).should()

contract('DYDXERC3156', (accounts) => {

  const [ deployer, user1 ] = accounts;
  let weth, dai, usdc, borrower, solo, lender
  const soloBalance = new BN(100000);

  beforeEach(async function () {
    weth = await ERC20Mock.new("WETH", "WETH");
    dai = await ERC20Mock.new("DAI", "DAI");
    usdc = await ERC20Mock.new("USDC", "USDC");
    solo = await SoloMarginMock.new(
      [0, 1, 2],
      [weth.address, dai.address, usdc.address],  
    );
    lender = await DYDXERC3156.new(solo.address);

    borrower = await FlashBorrower.new()

    await weth.mint(solo.address, soloBalance.toString());
    await dai.mint(solo.address, soloBalance.toString());
    await weth.mint(borrower.address, 2);
    await dai.mint(borrower.address, 2);
  });

  it('flash supply', async function () {
    expect(await lender.maxFlashAmount(weth.address)).to.be.bignumber.equal(soloBalance);
    expect(await lender.maxFlashAmount(usdc.address)).to.be.bignumber.equal("0");
    expect(await lender.maxFlashAmount(lender.address)).to.be.bignumber.equal("0");
  });

  it('flash fee', async function () {
    expect(await lender.flashFee(weth.address, soloBalance)).to.be.bignumber.equal("2");
    expect(await lender.flashFee(usdc.address, soloBalance)).to.be.bignumber.equal("2");
    await expectRevert(
      lender.flashFee(lender.address, soloBalance),
      "Unsupported currency"
    )
  });

  it('weth flash loan', async function () {
    const fee = await lender.flashFee(weth.address, soloBalance)

    await borrower.flashBorrow(lender.address, weth.address, soloBalance, { from: user1 });
    expect(await weth.balanceOf(solo.address)).to.be.bignumber.equal(soloBalance.add(fee));

    const balanceAfter = await weth.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(soloBalance.add(fee).toString())
    const flashToken = await borrower.flashToken()
    flashToken.toString().should.equal(weth.address)
    const flashAmount = await borrower.flashAmount()
    flashAmount.toString().should.equal(soloBalance.toString())
    const flashFee = await borrower.flashFee()
    flashFee.toString().should.equal(fee.toString())
    const flashSender = await borrower.flashSender()
    flashSender.toString().should.equal(borrower.address)
  });

  it('dai flash loan', async function () {
    const fee = await lender.flashFee(dai.address, soloBalance)

    await borrower.flashBorrow(lender.address, dai.address, soloBalance, { from: user1 });
    expect(await dai.balanceOf(solo.address)).to.be.bignumber.equal(soloBalance.add(fee));

    const balanceAfter = await dai.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(soloBalance.add(fee).toString())
    const flashToken = await borrower.flashToken()
    flashToken.toString().should.equal(dai.address)
    const flashAmount = await borrower.flashAmount()
    flashAmount.toString().should.equal(soloBalance.toString())
    const flashFee = await borrower.flashFee()
    flashFee.toString().should.equal(fee.toString())
    const flashSender = await borrower.flashSender()
    flashSender.toString().should.equal(borrower.address)
  });
});