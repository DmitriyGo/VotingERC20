import { parseEther } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

import { verify } from '../utils';

const CONTRACT_NAME = 'ERC20Tradable';

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;
  const { deployer } = await getNamedAccounts();

  const name = 'VotableToken';
  const symbol = 'VOTE';
  const initialSupply = parseEther(String(1_000_000));
  const initialPrice = parseEther('1');
  const timeToVote = 7 * 24 * 60 * 60; // 7 days in seconds

  const result = await deploy(CONTRACT_NAME, {
    from: deployer,
    args: [name, symbol, initialSupply, initialPrice, timeToVote],
    log: true,
    autoMine: true,
  });

  if (result.newlyDeployed && result.transactionHash) {
    await verify(hre, result.address, result.transactionHash, [
      name,
      symbol,
      initialSupply.toString(),
      initialPrice.toString(),
      timeToVote,
    ]);
  }
};

func.tags = ['core', CONTRACT_NAME];
func.id = CONTRACT_NAME;

export default func;
