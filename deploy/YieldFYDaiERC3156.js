const addresses = {
  '1' : {
      'fyDais': [
        "0x9D7e85d095934471a2788F485A3c765d0A463bD7",
        "0x3DeCA9aF98F59eD5125D1F697aBAd2aF45036332",
        "0x269A30E0fD5231438017dC0438f818A80dC4464B",
        "0xe523442a6c083016E2F430ab0780250ef4438536",
        "0xF2C9c61487D796032cdb9d57f770121218AC5F91",
      ],
  },
  '42' : {
      'fyDais': [
        "0x6B166d6325586c86B44f01509Fc64e649DCfE7C4",
        "0x42AA68930d4430E2416036966983E6c9Fe8Ff2f8",
        "0x2b67866649AFcEFC63870E02EdefC318fd8760D3",
        "0x02B06417A3e3CB391970C6074AbcF2745a60b880",
        "0x6Abb65246346b2A52Faed338cB18880e70A57Cf8",
      ],
  }
}

const func = async function ({ deployments, getNamedAccounts, getChainId }) {
  const { deploy, read, execute } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId()

  if (chainId === '31337') { // buidlerevm's chainId
    console.log('Local deployments not implemented')
    return
  } else {
    const lender = await deploy('YieldFYDaiERC3156', {
      from: deployer,
      deterministicDeployment: true,
      args: [
        addresses[chainId]['fyDais'],
      ],
    })
    console.log(`Deployed YieldFYDaiERC3156 to ${lender.address}`);
  }
};

module.exports = func;
module.exports.tags = ["YieldFYDaiERC3156"];