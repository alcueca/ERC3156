const addresses = {
    '1' : {
        'LendingPoolAddressProvider': '0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5'
    },
    '42' : {
        'LendingPoolAddressProvider': '0x652B2937Efd0B5beA1c8d54293FC1289672AFC6b'
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
      const lender = await deploy('AaveERC3156', {
        from: deployer,
        deterministicDeployment: true,
        args: [
          addresses[chainId]['LendingPoolAddressProvider'],
        ],
      })
      console.log(`Deployed AaveERC3156 to ${lender.address}`);
    }
  };
  
  module.exports = func;
  module.exports.tags = ["AaveERC3156"];
  