import { ZeroHash, parseEther, parseUnits } from 'ethers';
import { ethers } from 'hardhat';

import { tokenFixture } from '../fixtures/tokenFixture';

describe('ERC20Votable', function () {
  it('should initialize the ERC20Votable correctly', async function () {
    const { deployer, user1, user2, user3, erc20 } = await tokenFixture();

    const totalSupply = await erc20.totalSupply();
    console.log('totalSupply ==>', totalSupply);

    const value1 = parseUnits('1000');
    const value2 = parseUnits('500');
    const price1 = parseEther('2');
    const price2 = parseEther('3');
    console.log('totalSupply==>', await erc20.totalSupply());
    await erc20.connect(deployer).transfer(user1, value1);
    await erc20.connect(user1).startVoting(price1);

    console.log('user1 balance', await erc20.balanceOf(user1));
    await erc20.connect(user1).buy({ value: parseEther('1') });
    console.log('user1 balance', await erc20.balanceOf(user1));
    console.log('totalSupply==>', await erc20.totalSupply());
    await erc20.connect(deployer).transfer(user2, ((await erc20.totalSupply()) * 5n) / 10000n);
    await erc20.connect(user2).castVote(price2, ZeroHash);

    await erc20.connect(deployer).transfer(user3, ((await erc20.totalSupply()) * 5n) / 10000n);
    await erc20.connect(user3).castVote(price1, await erc20.getId(1, price2));
  });
});
