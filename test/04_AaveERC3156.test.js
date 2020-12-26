const AToken = artifacts.require('ATokenMock')
const ERC20Currency = artifacts.require('ERC20Mock')
const LendingPoolAddressesProvider = artifacts.require('LendingPoolAddressesProviderMock')
const LendingPool = artifacts.require('LendingPoolMock')
const AaveERC3156 = artifacts.require('AaveERC3156')
const FlashBorrower = artifacts.require('FlashBorrower')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

const MAX = '115792089237316195423570985008687907853269984665640564039457584007913129639935'

contract('AaveERC3156', (accounts) => {
  const [deployer, user1] = accounts
  let weth, dai, aWeth, aDai, lendingPool, lendingPoolAddressProvider, lender
  let borrower
  const aaveBalance = new BN(100000);

  beforeEach(async () => {
    weth = await ERC20Currency.new("WETH", "WETH", { from: deployer })
    dai = await ERC20Currency.new("DAI", "DAI", { from: deployer })
    aWeth = await AToken.new(weth.address, "AToken1", "ATST1", { from: deployer })
    aDai = await AToken.new(dai.address, "Atoken2", "ATST2", { from: deployer })
    lendingPool = await LendingPool.new({ from: deployer })
    await lendingPool.addReserve(aWeth.address, { from: deployer })
    await lendingPool.addReserve(aDai.address, { from: deployer })
    lendingPoolAddressProvider = await LendingPoolAddressesProvider.new(lendingPool.address, { from: deployer })
    lender = await AaveERC3156.new(lendingPoolAddressProvider.address, { from: deployer })

    borrower = await FlashBorrower.new(weth.address, { from: deployer })

    await weth.mint(aWeth.address, aaveBalance, { from: deployer })
    await dai.mint(aDai.address, aaveBalance, { from: deployer })
  })

  it('flash supply', async function () {
    expect(await lender.flashSupply(weth.address)).to.be.bignumber.equal(aaveBalance);
    expect(await lender.flashSupply(dai.address)).to.be.bignumber.equal(aaveBalance);
    expect(await lender.flashSupply(lender.address)).to.be.bignumber.equal("0");
  });

  it('flash fee', async function () {
    expect(await lender.flashFee(weth.address, aaveBalance)).to.be.bignumber.equal(aaveBalance.muln(9).divn(10000));
    expect(await lender.flashFee(dai.address, aaveBalance)).to.be.bignumber.equal(aaveBalance.muln(9).divn(10000));
    await expectRevert(
      lender.flashFee(lender.address, aaveBalance),
      "Unsupported currency"
    )
  });

  it('weth flash loan', async () => {
    const fee = aaveBalance.muln(9).divn(10000)
    await weth.mint(borrower.address, fee, { from: user1 })
    await borrower.flashBorrow(lender.address, aaveBalance, { from: user1 })

    const balanceAfter = await weth.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await borrower.flashBalance()
    flashBalance.toString().should.equal(aaveBalance.add(fee).toString())
    const flashValue = await borrower.flashValue()
    flashValue.toString().should.equal(aaveBalance.toString())
    const flashFee = await borrower.flashFee()
    flashFee.toString().should.equal(fee.toString())
    const flashUser = await borrower.flashUser()
    flashUser.toString().should.equal(borrower.address)
  })
})
