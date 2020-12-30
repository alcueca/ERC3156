const addresses = {
  '1' : {
      'fyDaiLP21Mar31': '0xb39221E6790Ae8360B7E8C1c7221900fad9397f9',
  },
  '42' : {
      'fyDaiLP21Mar31': '0x08cc239a994A10118CfdeEa9B849C9c674C093d3',
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
    const lender = await deploy('YieldDaiERC3156', {
      from: deployer,
      deterministicDeployment: true,
      args: [
        addresses[chainId]['fyDaiLP21Mar31'],
      ],
    })
    console.log(`Deployed YieldDaiERC3156 to ${lender.address}`);
  }
};

module.exports = func;
module.exports.tags = ["YieldDaiERC3156"];