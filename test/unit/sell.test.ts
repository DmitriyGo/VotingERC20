import { expect } from 'chai';
import { ethers } from 'hardhat';

import { tokenFixture } from '../fixtures/tokenFixture';

describe('sell', function () {
  it('should allow a user to sell tokens', async function () {
    const { user1, erc20, erc20Address } = await tokenFixture();

    const initialPrice = 1n * 10n ** 18n; // 1 ETH per token
    const buyAmount = 10n * 10n ** 18n; // 10 ETH

    await erc20.connect(user1)['buy()']({ value: buyAmount });

    const tokensToSell = await erc20.balanceOf(user1.address);
    const expectedEtherWithoutFee = (tokensToSell * initialPrice) / 10n ** 18n;

    const sellFeePercentage = await erc20.sellFeePercentage();
    const buyFeePercentage = await erc20.buyFeePercentage();
    const percentage = await erc20.PERCENTAGE();

    const sellFee = (expectedEtherWithoutFee * sellFeePercentage) / percentage;

    const expectedEtherWithFee = expectedEtherWithoutFee - sellFee;

    const contractBalanceAfterBuy = await erc20.balanceOf(erc20Address);

    await expect(() => erc20.connect(user1)['sell(uint256)'](tokensToSell)).to.changeEtherBalances(
      [user1, erc20],
      [expectedEtherWithFee, -expectedEtherWithFee],
    );

    const userBalance = await erc20.balanceOf(user1.address);
    const contractTokenBalance = await erc20.balanceOf(erc20Address);
    const contractEthBalance = await ethers.provider.getBalance(erc20Address);

    const expectedTokensWithoutFee = (buyAmount * 10n ** 18n) / initialPrice;
    const buyFee = (expectedTokensWithoutFee * buyFeePercentage) / percentage;
    const totalFee = buyFee + (tokensToSell * sellFeePercentage) / percentage;

    expect(userBalance).to.equal(0n);
    expect(contractTokenBalance).to.equal(totalFee);
    expect(contractEthBalance).to.equal(contractBalanceAfterBuy + sellFee);
  });
});
