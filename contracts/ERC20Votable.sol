// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./ERC20.sol";

import "hardhat/console.sol";

contract ERC20Votable is ERC20, AccessControl, ReentrancyGuard {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  uint256 private constant PERCENTAGE = 10000;

  uint256 private constant minPercentageToInitiateVoting = 1e15; // 0.1% in wei percentage
  uint256 private constant minPercentageToVote = 5e14; // 0.05% in wei percentage

  uint256 public timeToVote;
  uint256 public currentPrice;

  struct Voting {
    bool active;
    uint256 startTime;
    uint256 endTime;
    mapping(uint256 => uint256) votes;
    uint256 leadingPrice;
    uint256 highestVotes;
  }

  Voting public currentVoting;

  uint256 private buyFeePercentage;
  uint256 private sellFeePercentage;
  uint256 private lastFeeCollectionTimestamp;

  event VotingStarted(uint256 startTime, uint256 endTime);
  event VoteCasted(address voter, uint256 price, uint256 voteCount);
  event VotingEnded(uint256 winningPrice);
  event FeeCollected(uint256 amount);

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 initialSupply,
    uint256 initialPrice,
    uint256 _timeToVote
  ) ERC20(name_, symbol_) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ADMIN_ROLE, msg.sender);

    _mint(msg.sender, initialSupply);
    currentPrice = initialPrice;
    timeToVote = _timeToVote;

    buyFeePercentage = 3000;
    sellFeePercentage = 3000;
  }

  function startVoting(uint256 price) external {
    require(!currentVoting.active, "Voting already active");
    console.log("balanceOf(msg.sender)", balanceOf(msg.sender));
    console.log(
      "(totalSupply() * minPercentageToInitiateVoting) / 1e18",
      (totalSupply() * minPercentageToInitiateVoting) / 1e18
    );

    require(
      balanceOf(msg.sender) >= (totalSupply() * minPercentageToInitiateVoting) / 1e18,
      "Insufficient balance to initiate voting"
    );

    currentVoting.active = true;
    currentVoting.startTime = block.timestamp;
    currentVoting.endTime = block.timestamp + timeToVote;

    _castVote(msg.sender, price);

    emit VotingStarted(currentVoting.startTime, currentVoting.endTime);
  }

  function vote(uint256 price) external {
    require(currentVoting.active, "No active voting");
    require(block.timestamp <= currentVoting.endTime, "Voting has ended");
    require(balanceOf(msg.sender) >= (totalSupply() * minPercentageToVote) / 1e18, "Insufficient balance to vote");

    _castVote(msg.sender, price);
  }

  function _castVote(address voter, uint256 price) private {
    uint256 voterBalance = balanceOf(voter);
    currentVoting.votes[price] += voterBalance;

    if (currentVoting.votes[price] > currentVoting.highestVotes) {
      currentVoting.leadingPrice = price;
      currentVoting.highestVotes = currentVoting.votes[price];
    }

    emit VoteCasted(voter, price, voterBalance);
  }

  function endVoting() external onlyRole(ADMIN_ROLE) {
    require(currentVoting.active, "No active voting");
    require(block.timestamp > currentVoting.endTime, "Voting not yet ended");

    currentVoting.active = false;
    currentPrice = currentVoting.leadingPrice;

    emit VotingEnded(currentPrice);
  }

  function buy() external payable nonReentrant {
    uint256 tokensWithoutFee = (msg.value * (1e18)) / currentPrice;
    uint256 fee = (tokensWithoutFee * buyFeePercentage) / PERCENTAGE;
    uint256 tokensWithFee = tokensWithoutFee - fee;
    _mint(msg.sender, tokensWithFee);
    _mint(address(this), fee);
  }

  function sell(uint256 tokenAmount) external nonReentrant {
    uint256 etherAmountWithoutFee = (tokenAmount * currentPrice) / 1e18;
    uint256 fee = (etherAmountWithoutFee * sellFeePercentage) / PERCENTAGE;
    uint256 etherAmountWithFee = etherAmountWithoutFee - fee;
    require(address(this).balance >= etherAmountWithFee, "Insufficient ETH in contract");
    _burn(msg.sender, tokenAmount);
    _mint(address(this), (fee * 1e18) / currentPrice);
    payable(msg.sender).transfer(etherAmountWithFee);
  }

  function collectAndBurnFees() external onlyRole(ADMIN_ROLE) {
    require(block.timestamp >= lastFeeCollectionTimestamp + 7 days, "Fees can only be collected weekly");
    uint256 feeAmount = balanceOf(address(this));
    _burn(address(this), feeAmount);
    emit FeeCollected(feeAmount);
    lastFeeCollectionTimestamp = block.timestamp;
  }

  function setFees(uint256 _buyFeePercentage, uint256 _sellFeePercentage) external onlyRole(ADMIN_ROLE) {
    require(
      _buyFeePercentage <= PERCENTAGE && _sellFeePercentage <= PERCENTAGE,
      "Fee basis points must be between 0 and 10000"
    );
    buyFeePercentage = _buyFeePercentage;
    sellFeePercentage = _sellFeePercentage;
  }

  function grantAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(ADMIN_ROLE, account);
  }

  function revokeAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(ADMIN_ROLE, account);
  }
}
