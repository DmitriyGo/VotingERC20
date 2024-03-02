// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./ERC20.sol";

import "hardhat/console.sol";

contract ERC20Votable is ERC20, AccessControl {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

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

  Voting private currentVoting;
  mapping(uint256 => bool) private priceExists;

  uint256 private buyFeePercentage;
  uint256 private sellFeePercentage;

  event VotingStarted(uint256 startTime, uint256 endTime);
  event VoteCasted(address voter, uint256 price, uint256 voteCount);
  event VotingEnded(uint256 winningPrice);

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

  function setFees(uint256 _buyFeePercentage, uint256 _sellFeePercentage) external onlyRole(ADMIN_ROLE) {
    require(_buyFeePercentage <= 100 && _sellFeePercentage <= 100, "Fee percentages must be between 0 and 100");
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
