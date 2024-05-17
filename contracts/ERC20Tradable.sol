// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20Votable} from "./ERC20Votable.sol";
import {VotingData} from "./utils/VotingLinkedList.sol";
import "hardhat/console.sol";

contract ERC20Tradable is ERC20Votable {
  uint256 public constant PERCENTAGE = 10000;

  uint256 public buyFeePercentage;
  uint256 public sellFeePercentage;
  uint256 public lastFeeCollectionTimestamp;

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
    require(msg.value > 0, "Must send ETH to buy tokens");
    uint256 tokensWithoutFee = (msg.value * 1e18) / currentPrice;
    uint256 fee = _calculateFee(tokensWithoutFee, buyFeePercentage);
    uint256 tokensWithFee = tokensWithoutFee - fee;
    _mint(msg.sender, tokensWithFee);
    _mint(address(this), fee);
  }

  function buy(bytes32 previousId) external payable nonReentrant voted {
    require(msg.value > 0, "Must send ETH to buy tokens");
    uint256 tokensWithoutFee = (msg.value * 1e18) / currentPrice;
    uint256 fee = _calculateFee(tokensWithoutFee, buyFeePercentage);
    uint256 tokensWithFee = tokensWithoutFee - fee;
    _mint(msg.sender, tokensWithFee);
    _mint(address(this), fee);

    uint256 price = _voterToPrice[_votingRoundId][msg.sender];
    VotingData memory data = getByPrice(_votingRoundId, price);
    insert(_votingRoundId, price, data.amount + tokensWithFee, previousId);
    traverse();
  }

  function sell(uint256 tokenAmount) external nonReentrant notVoted {
    require(tokenAmount > 0, "Must sell more than 0 tokens");

    uint256 etherAmountWithoutFee = (tokenAmount * currentPrice) / 1e18;
    uint256 etherFee = _calculateFee(etherAmountWithoutFee, sellFeePercentage);
    uint256 etherAmountWithFee = etherAmountWithoutFee - etherFee;
    require(address(this).balance >= etherAmountWithFee, "Insufficient ETH in contract");

    uint256 tokenFee = _calculateFee(tokenAmount, sellFeePercentage);
    uint256 tokensToBurn = tokenAmount - tokenFee;

    _transfer(msg.sender, address(this), tokenAmount);
    _burn(address(this), tokensToBurn);
    payable(msg.sender).transfer(etherAmountWithFee);
  }

  function sell(uint256 tokenAmount, bytes32 previousId) external nonReentrant voted {
    uint256 etherAmountWithoutFee = (tokenAmount * currentPrice) / 1e18;
    uint256 fee = _calculateFee(etherAmountWithoutFee, sellFeePercentage);
    uint256 etherAmountWithFee = etherAmountWithoutFee - fee;
    require(address(this).balance >= etherAmountWithFee, "Insufficient ETH in contract");
    _burn(msg.sender, tokenAmount);
    payable(msg.sender).transfer(etherAmountWithFee);

    uint256 price = _voterToPrice[_votingRoundId][msg.sender];
    VotingData memory data = getByPrice(_votingRoundId, price);
    insert(_votingRoundId, price, data.amount - tokenAmount, previousId);
    traverse();
  }

  function transfer(address _to, uint256 _value) public override notVoted returns (bool) {
    bool result = super.transfer(_to, _value);
    return result;
  }

  function transfer(address to, uint256 value, bytes32 previousId1, bytes32 previousId2) public voted returns (bool) {
    bool result = super.transfer(to, value);
    _updateVotingPower(msg.sender, to, value, previousId1, previousId2);
    traverse();
    return result;
  }

  function transferFrom(address _from, address _to, uint256 _value) public override notVoted returns (bool) {
    bool result = super.transferFrom(_from, _to, _value);
    return result;
  }

  function transferFrom(
    address from,
    address to,
    uint256 value,
    bytes32 previousId1,
    bytes32 previousId2
  ) public voted returns (bool) {
    bool result = super.transferFrom(from, to, value);
    _updateVotingPower(from, to, value, previousId1, previousId2);
    traverse();
    return result;
  }

  function _updateVotingPower(
    address from,
    address to,
    uint256 amount,
    bytes32 previousId1,
    bytes32 previousId2
  ) private {
    if (from != address(0)) {
      uint256 fromPrice = _voterToPrice[_votingRoundId][from];
      VotingData memory fromData = getByPrice(_votingRoundId, fromPrice);
      if (fromData.amount >= amount) {
        insert(_votingRoundId, fromPrice, fromData.amount - amount, previousId1);
      }
    }

    if (to != address(0)) {
      uint256 toPrice = _voterToPrice[_votingRoundId][to];
      VotingData memory toData = getByPrice(_votingRoundId, toPrice);
      insert(_votingRoundId, toPrice, toData.amount + amount, previousId2);
    }
  }

  function collectAndBurnFees() external onlyRole(ADMIN_ROLE) {
    require(block.timestamp >= lastFeeCollectionTimestamp + 7 days, "Fees can only be collected weekly");
    uint256 feeAmount = balanceOf(address(this));
    _burn(address(this), feeAmount);
    emit FeeCollected(feeAmount);
    lastFeeCollectionTimestamp = block.timestamp;
  }

  function _calculateFee(uint256 amount, uint256 feePercentage) internal pure returns (uint256) {
    return (amount * feePercentage) / PERCENTAGE;
  }

  function setFees(uint256 buyFeePercentage_, uint256 sellFeePercentage_) external onlyRole(ADMIN_ROLE) {
    require(
      buyFeePercentage_ <= PERCENTAGE && sellFeePercentage_ <= PERCENTAGE,
      "Fee basis points must be between 0 and 10000"
    );
    buyFeePercentage = buyFeePercentage_;
    sellFeePercentage = sellFeePercentage_;
  }
}
