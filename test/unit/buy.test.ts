import { expect } from 'chai';
import { parseEther } from 'ethers';

import { tokenFixture } from '../fixtures/tokenFixture';

describe('buy', function () {
  it('should allow a user to buy tokens', async function () {
    const { user1, erc20, erc20Address } = await tokenFixture();

    const initialPrice = parseEther('1');
    const buyAmount = 10n * 10n ** 18n; // 10 ETH
    const expectedTokensWithoutFee = (buyAmount * 10n ** 18n) / initialPrice;
    const feePercentage = await erc20.buyFeePercentage();
    const percentage = await erc20.PERCENTAGE();
    const fee = (expectedTokensWithoutFee * feePercentage) / percentage;
    const expectedTokensWithFee = expectedTokensWithoutFee - fee;

    await expect(() => erc20.connect(user1)['buy()']({ value: buyAmount })).to.changeEtherBalances(
      [user1, erc20],
      [-BigInt(buyAmount), BigInt(buyAmount)],
    );

    expect(await erc20.balanceOf(user1.address)).to.equal(expectedTokensWithFee);
    expect(await erc20.balanceOf(erc20Address)).to.equal(fee);
  });
});
