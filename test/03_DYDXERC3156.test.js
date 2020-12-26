const { BN, expectEvent, expectRevert, balance } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { ethers } = require('ethers');

const SoloMarginMock = artifacts.require('SoloMarginMock');
const DYDXERC3156 = artifacts.require('DYDXERC3156');
const ERC20Mock = artifacts.require('ERC20Mock');
const FlashBorrower = artifacts.require('FlashBorrower');

/* function encodeExecute(testType, dataAbi, data) {
  const encodedData = ethers.utils.defaultAbiCoder.encode(dataAbi, data);
  return ethers.utils.defaultAbiCoder.encode(["uint256", "bytes"], [testType, encodedData]);
} */

contract('DYDXERC3156', (accounts) => {

  const [ deployer, user1 ] = accounts;
  let weth, sai, usdc, dai, borrowerWeth, borrowerDai, solo, lender
  const soloBalance = new BN(100000);

  beforeEach(async function () {
    weth = await ERC20Mock.new("WETH", "WETH", { from: deployer });
    sai = await ERC20Mock.new("SAI", "SAI", { from: deployer });
    usdc = await ERC20Mock.new("USDC", "USDC", { from: deployer });
    dai = await ERC20Mock.new("DAI", "DAI", { from: deployer });
    solo = await SoloMarginMock.new(
      [0, 1, 2, 3],
      [weth.address, sai.address, usdc.address, dai.address],
      { from: deployer }
    );
    lender = await DYDXERC3156.new(solo.address, { from: deployer });

    borrowerWeth = await FlashBorrower.new(weth.address, {from: deployer })
    borrowerDai = await FlashBorrower.new(dai.address, {from: deployer })

    await weth.mint(solo.address, soloBalance.toString(), { from: deployer });
    await dai.mint(solo.address, soloBalance.toString(), { from: deployer });
    await weth.mint(borrowerWeth.address, 1, { from: deployer });
    await dai.mint(borrowerDai.address, 2, { from: deployer });
  });

  describe('flash loan from dXdY', function () {

    it('flash supply', async function () {
      expect(await lender.flashSupply(weth.address)).to.be.bignumber.equal(soloBalance);
      expect(await lender.flashSupply(sai.address)).to.be.bignumber.equal("0");
      expect(await lender.flashSupply(lender.address)).to.be.bignumber.equal("0");
    });

    it('flash fee', async function () {
      expect(await lender.flashFee(weth.address, soloBalance)).to.be.bignumber.equal("1");
      expect(await lender.flashFee(dai.address, soloBalance)).to.be.bignumber.equal("2");
      await expectRevert(
        lender.flashFee(lender.address, soloBalance),
        "Unsupported currency"
      )
    });

    it('weth flash loan', async function () {
      await borrowerWeth.flashBorrow(lender.address, soloBalance, { from: user1 });
      expect(await weth.balanceOf(solo.address)).to.be.bignumber.equal(soloBalance.addn(1));
    });

    it('dai flash loan', async function () {
      await borrowerDai.flashBorrow(lender.address, soloBalance, { from: user1 });
      expect(await dai.balanceOf(solo.address)).to.be.bignumber.equal(soloBalance.addn(2));
    });
  });
});