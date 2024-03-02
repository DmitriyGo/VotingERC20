import { impersonateAccount } from '@nomicfoundation/hardhat-network-helpers';
import { AddressLike } from 'ethers';
import { ethers } from 'hardhat';

import { IERC20 } from '../../typechain-types';

export async function transferUsdt(contract: IERC20, to: AddressLike, amount: bigint) {
  const usdtHolderAddress = '0xF977814e90dA44bFA03b6295A0616a897441aceC';
  const usdtHolder = await ethers.getSigner(usdtHolderAddress);

  await impersonateAccount(usdtHolderAddress);
  await contract.connect(usdtHolder).transfer(to, amount);
}
