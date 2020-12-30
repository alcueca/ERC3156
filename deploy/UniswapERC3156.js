const addresses = {
    '1' : {
        'UniswapV2Factory': '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f',
        'Weth' : '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
        'Dai' : '0x6B175474E89094C44Da98b954EedeAC495271d0F',
    },
    '42' : {
        'UniswapV2Factory': '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f',
        'Weth' : '0xd0A1E359811322d97991E03f863a0C30C2cF029C',
        'Dai' : '0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa',
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
      const lender = await deploy('UniswapERC3156', {
        from: deployer,
        deterministicDeployment: true,
        args: [
          addresses[chainId]['UniswapV2Factory'],
          addresses[chainId]['Weth'],
          addresses[chainId]['Dai'],
        ],
      })
      console.log(`Deployed UniswapERC3156 to ${lender.address}`);
    }
  };
  
  module.exports = func;
  module.exports.tags = ["UniswapERC3156"];
  