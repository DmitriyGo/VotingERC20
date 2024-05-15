// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20Votable} from "./ERC20Votable.sol";
import {VotingData} from "./utils/VotingLinkedList.sol";

contract ERC20Tradable is ERC20Votable {
  uint256 private constant PERCENTAGE = 10000;

  uint256 private buyFeePercentage;
  uint256 private sellFeePercentage;
  uint256 private lastFeeCollectionTimestamp;

  event FeeCollected(uint256 amount);

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 initialSupply,
    uint256 initialPrice,
    uint256 _timeToVote
  ) ERC20Votable(name_, symbol_, initialSupply, _timeToVote) {
    currentPrice = initialPrice;
    buyFeePercentage = 3000;
    sellFeePercentage = 3000;
  }

  function buy() external payable nonReentrant notVoted {
    uint256 tokensWithoutFee = (msg.value * 1e18) / currentPrice;
    uint256 fee = calculateFee(tokensWithoutFee, buyFeePercentage);
    uint256 tokensWithFee = tokensWithoutFee - fee;
    _mint(msg.sender, tokensWithFee);
    _mint(address(this), fee);
  }

  function buy(bytes32 previousId) external payable nonReentrant voted {
    uint256 tokensWithoutFee = (msg.value * 1e18) / currentPrice;
    uint256 fee = calculateFee(tokensWithoutFee, buyFeePercentage);
    uint256 tokensWithFee = tokensWithoutFee - fee;
    _mint(msg.sender, tokensWithFee);
    _mint(address(this), fee);

    uint256 price = voterToPrice[votingRoundId][msg.sender];
    VotingData memory data = getByPrice(votingRoundId, price);
    insert(votingRoundId, price, data.amount + tokensWithFee, previousId);
  }

  function sell(uint256 tokenAmount) external nonReentrant notVoted {
    uint256 etherAmountWithoutFee = (tokenAmount * currentPrice) / 1e18;
    uint256 fee = calculateFee(etherAmountWithoutFee, sellFeePercentage);
    uint256 etherAmountWithFee = etherAmountWithoutFee - fee;
    require(address(this).balance >= etherAmountWithFee, "Insufficient ETH in contract");
    _burn(msg.sender, tokenAmount);
    _mint(address(this), fee);
    payable(msg.sender).transfer(etherAmountWithFee);
  }

  function sell(uint256 tokenAmount, bytes32 previousId) external nonReentrant voted {
    uint256 etherAmountWithoutFee = (tokenAmount * currentPrice) / 1e18;
    uint256 fee = calculateFee(etherAmountWithoutFee, sellFeePercentage);
    uint256 etherAmountWithFee = etherAmountWithoutFee - fee;
    require(address(this).balance >= etherAmountWithFee, "Insufficient ETH in contract");
    _burn(msg.sender, tokenAmount);
    _mint(address(this), fee);
    payable(msg.sender).transfer(etherAmountWithFee);

    uint256 price = voterToPrice[votingRoundId][msg.sender];
    VotingData memory data = getByPrice(votingRoundId, price);
    insert(votingRoundId, price, data.amount - tokenAmount, previousId);
  }

  function collectAndBurnFees() external onlyRole(ADMIN_ROLE) {
    require(block.timestamp >= lastFeeCollectionTimestamp + 7 days, "Fees can only be collected weekly");
    uint256 feeAmount = balanceOf(address(this));
    _burn(address(this), feeAmount);
    emit FeeCollected(feeAmount);
    lastFeeCollectionTimestamp = block.timestamp;
  }

  function calculateFee(uint256 amount, uint256 feePercentage) internal pure returns (uint256) {
    return (amount * feePercentage) / PERCENTAGE;
  }

  function setFees(uint256 _buyFeePercentage, uint256 _sellFeePercentage) external onlyRole(ADMIN_ROLE) {
    require(
      _buyFeePercentage <= PERCENTAGE && _sellFeePercentage <= PERCENTAGE,
      "Fee basis points must be between 0 and 10000"
    );
    buyFeePercentage = _buyFeePercentage;
    sellFeePercentage = _sellFeePercentage;
  }
}
