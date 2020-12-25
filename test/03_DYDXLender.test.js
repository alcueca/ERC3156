const { BN, expectEvent, expectRevert, balance } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { ethers } = require('ethers');

const MockSoloMargin = artifacts.require('MockSoloMargin');
const SoloLiquidityProxy = artifacts.require('SoloLiquidityProxy');
const ERC20Mock = artifacts.require('ERC20Mock');
const FlashBorrower = artifacts.require('FlashBorrower');

/* function encodeExecute(testType, dataAbi, data) {
  const encodedData = ethers.utils.defaultAbiCoder.encode(dataAbi, data);
  return ethers.utils.defaultAbiCoder.encode(["uint256", "bytes"], [testType, encodedData]);
} */

contract('SoloLiquidityProxy', (accounts) => {

  const [ deployer, user1 ] = accounts;
  const soloBalance = new BN(100000);

  beforeEach(async function () {
    this.erc20 = await ERC20Mock.new("Test", "TT", { from: deployer });
    this.borrower = await FlashBorrower.new(this.erc20.address, {from: deployer })
    this.solo = await MockSoloMargin.new([1], [this.erc20.address], { from: deployer });

    this.proxy = await SoloLiquidityProxy.new(this.solo.address, { from: deployer });
    await this.proxy.registerPool(1, { from: deployer });

    await this.erc20.mint(this.solo.address, soloBalance.toString(), { from: deployer });
    await this.erc20.mint(this.borrower.address, 2, { from: deployer });
  });

  describe('flash loan from dXdY', function () {
    const underlyingAmount = soloBalance;

    beforeEach(async function () {
      await this.borrower.flashBorrow(this.proxy.address, underlyingAmount, { from: user1 });
    });

    it('increments solo balance', async function () {
      expect(await this.erc20.balanceOf(this.solo.address)).to.be.bignumber.equal(soloBalance.addn(1));
    });
  });
});