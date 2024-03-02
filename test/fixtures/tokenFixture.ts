import { deployments } from 'hardhat';

export const tokenFixture = deployments.createFixture(async ({ deployments, getNamedAccounts, ethers }) => {
  const { deployer: deployerAddress, user1: user1Address, user2: user2Address } = await getNamedAccounts();

  const deployer = await ethers.getSigner(deployerAddress);
  const user1 = await ethers.getSigner(user1Address);
  const user2 = await ethers.getSigner(user2Address);

  await deployments.fixture(['core']);

  const erc20 = await ethers.getContractAt('ERC20Votable', (await deployments.get('ERC20Votable')).address, deployer);

  return {
    deployer,
    user1,
    user2,
    erc20,
  };
});
