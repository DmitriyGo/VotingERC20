import { parseEther, parseUnits } from 'ethers';

import { tokenFixture } from '../fixtures/tokenFixture';

describe('ERC20Votable', function () {
  it('should initialize the ERC20Votable correctly', async function () {
    const { deployer, user1, user2, erc20 } = await tokenFixture();

    const totalSupply = await erc20.totalSupply();
    console.log('totalSupply ==>', totalSupply);

    const value = parseUnits('1000');

    await erc20.connect(deployer).transfer(user1, value);

    console.log('value ==>', value);
    await erc20.connect(user1).startVoting(value);

    console.log('currentVoting ==>', await erc20.currentVoting());

    console.log('user1 balance', await erc20.balanceOf(user1));
    await erc20.connect(user1).buy({ value: parseEther('1') });
    console.log('user1 balance', await erc20.balanceOf(user1));

    console.log('currentVoting ==>', await erc20.currentVoting());
  });
});
