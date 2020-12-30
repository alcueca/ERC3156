const addresses = {
    '1' : {
        'SoloMargin': '0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e'
    },
    '42' : {
        'SoloMargin': '0x4EC3570cADaAEE08Ae384779B0f3A45EF85289DE'
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
      const lender = await deploy('DYDXERC3156', {
        from: deployer,
        deterministicDeployment: true,
        args: [addresses[chainId]['SoloMargin']],
      })
      console.log(`Deployed DYDXERC3156 to ${lender.address}`);
    }
  };
  
  module.exports = func;
  module.exports.tags = ["DYDXERC3156"];
  