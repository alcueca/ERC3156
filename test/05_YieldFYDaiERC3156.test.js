const { BN, expectEvent, expectRevert, balance } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const YieldFYDaiERC3156 = artifacts.require('YieldFYDaiERC3156');
const FYDaiMock = artifacts.require('FYDaiMock');
const FlashBorrower = artifacts.require('FlashBorrower');

contract('YieldFYDaiERC3156', (accounts) => {

  const [ deployer, user1 ] = accounts;

  beforeEach(async function () {
    // Setup fyDai
    const block = await web3.eth.getBlockNumber()
    maturity0 = (await web3.eth.getBlock(block)).timestamp + 15778476 // Six months

    fyDai = await FYDaiMock.new("Test", "TST", maturity0, {from: deployer })
    lender = await YieldFYDaiERC3156.new({from: deployer })
    borrower = await FlashBorrower.new(fyDai.address, {from: deployer })
  });

  it('simple flash loan', async function () {
    const loan = new BN("1000")
    const balanceBefore = await fyDai.balanceOf(borrower.address)
    await borrower.flashBorrow(lender.address, loan, { from: user1 });

    assert.equal(await borrower.flashUser(), borrower.address)
    assert.equal((await borrower.flashValue()).toString(), loan.toString())
    assert.equal((await borrower.flashBalance()).toString(), balanceBefore.add(loan).toString())
    assert.equal((await borrower.flashFee()).toString(), "0")
    assert.equal((await fyDai.balanceOf(borrower.address)).toString(), balanceBefore.toString())
  });
});