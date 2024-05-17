import { deployments } from 'hardhat';

export const tokenFixture = deployments.createFixture(async ({ deployments, getNamedAccounts, ethers }) => {
  const {
    deployer: deployerAddress,
    user1: user1Address,
    user2: user2Address,
    user3: user3Address,
  } = await getNamedAccounts();

  const deployer = await ethers.getSigner(deployerAddress);
  const user1 = await ethers.getSigner(user1Address);
  const user2 = await ethers.getSigner(user2Address);
  const user3 = await ethers.getSigner(user3Address);

  await deployments.fixture(['core']);

  const erc20Address = (await deployments.get('ERC20Tradable')).address;
  const erc20 = await ethers.getContractAt('ERC20Tradable', erc20Address, deployer);

  return {
    deployer,
    user1,
    user2,
    user3,
    erc20,
    erc20Address,
  };
});
