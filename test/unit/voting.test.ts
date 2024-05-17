import { expect } from 'chai';
import { ZeroHash, parseEther } from 'ethers';

import { tokenFixture } from '../fixtures/tokenFixture';

describe('voting', function () {
  it("should not allow to start a voting if user doesn't have enough balance", async function () {
    const { user1, erc20 } = await tokenFixture();
    const desiredPrice = parseEther('2');
    await expect(await erc20.connect(user1).startVoting(desiredPrice)).to.be.revertedWith(
      'Insufficient balance to initiate voting',
    );
  });

  it.only('should allow to start a voting if user has enough balance', async function () {
    const { user1, erc20 } = await tokenFixture();
    const desiredPrice = parseEther('2');

    await erc20.connect(user1)['buy()']({ value: parseEther('1500') });

    await expect(erc20.connect(user1).startVoting(desiredPrice)).to.emit(erc20, 'VotingStarted');
  });

  it('should not allow to vote if there is not active voting', async function () {
    const { user1, erc20 } = await tokenFixture();
    const desiredPrice = parseEther('2');
    await expect(await erc20.connect(user1).castVote(desiredPrice, ZeroHash)).to.be.revertedWith(
      'Insufficient balance to initiate voting',
    );
  });
});
