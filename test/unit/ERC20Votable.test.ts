import { parseUnits } from 'ethers';
import { ethers } from 'hardhat';

import { tokenFixture } from '../fixtures/tokenFixture';
import { increaseTime } from '../helpers/increaseTime';

describe('ERC20Votable', function () {
  it('should initialize the ERC20Votable correctly', async function () {
    const { deployer, user1, user2, erc20 } = await tokenFixture();

    const totalSupply = await erc20.totalSupply();
    console.log('totalSupply ==>', totalSupply);

    const value = parseUnits('1000');
    const value2 = parseUnits('400');

    await erc20.connect(deployer).transfer(user1, value);
    await erc20.connect(deployer).transfer(user2, value2);

    console.log('value ==>', value);
    await erc20.connect(user1).startVoting(value);

    await erc20.connect(user2).vote(value2);

    const currentVoting = await erc20.currentVoting();
    console.log('currentVoting ==>', currentVoting);
  });
});
