// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {VotingLinkedList, VotingData} from "./utils/VotingLinkedList.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC20.sol";
import "hardhat/console.sol";

contract ERC20Votable is ERC20, AccessControl, ReentrancyGuard, VotingLinkedList {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  uint256 private constant PERCENTAGE = 10000;

  uint256 private constant minPercentageToInitiateVoting = 1e15; // 0.1% in wei percentage
  uint256 private constant minPercentageToVote = 5e14; // 0.05% in wei percentage

  uint256 public timeToVote;
  uint256 public currentPrice;

  bool public isVotingActive;
  uint256 public votingStartTime;
  uint256 public votingEndTime;
  uint256 private votingRoundId;
  uint256 private votingRoundLeadingPrice;
  mapping(uint256 => mapping(address => bool)) hasVoted;

  uint256 private buyFeePercentage;
  uint256 private sellFeePercentage;
  uint256 private lastFeeCollectionTimestamp;

  event VotingStarted(uint256 indexed roundId, uint256 startTime, uint256 endTime);
  event VoteCast(uint256 indexed roundId, address indexed voter, uint256 price);
  event VotingEnded(uint256 indexed roundId, uint256 newPrice);
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
    votingRoundId = 1;
  }

  function startVoting(uint256 price) external {
    require(!isVotingActive, "Voting already active");
    require(
      balanceOf(msg.sender) >= (totalSupply() * minPercentageToInitiateVoting) / 1e18,
      "Insufficient balance to initiate voting"
    );

    isVotingActive = true;
    votingStartTime = block.timestamp;
    votingEndTime = block.timestamp + timeToVote;

    _castVote(msg.sender, price, bytes32(0));

    emit VotingStarted(votingRoundId, votingStartTime, votingEndTime);
  }

  function _castVote(address voter, uint256 price, bytes32 previousId) internal {
    require(isVotingActive, "No active voting session");
    require(balanceOf(voter) >= (totalSupply() * minPercentageToVote) / 1e18, "Insufficient balance to vote");
    require(!hasVoted[votingRoundId][voter], "Already voted");
    require(price > 0, "Price must be positive number");

    uint256 tokenAmount = balanceOf(voter);
    insert(votingRoundId, price, tokenAmount, previousId);
    hasVoted[votingRoundId][voter] = true;
    traverse();
    console.log("\n");
    emit VoteCast(votingRoundId, voter, price);
  }

  function castVote(uint256 price, bytes32 previousId) external {
    _castVote(msg.sender, price, previousId);
  }

  function endVote() external onlyRole(ADMIN_ROLE) {
    require(isVotingActive, "No active voting session");
    require(block.timestamp >= votingEndTime, "Voting period has not ended");

    VotingData memory leadingData = getById(getId(votingRoundId, votingRoundLeadingPrice));
    currentPrice = leadingData.price;

    isVotingActive = false;
    votingStartTime = 0;
    votingEndTime = 0;
    votingRoundLeadingPrice = 0;

    votingRoundId++;
    clear(); // Clear the list for the next voting round

    emit VotingEnded(votingRoundId, currentPrice);
  }

  function calculateFee(uint256 amount, uint256 feePercentage) internal pure returns (uint256) {
    return (amount * feePercentage) / PERCENTAGE;
  }

  function buy() external payable nonReentrant {
    uint256 tokensWithoutFee = (msg.value * 1e18) / currentPrice;
    uint256 fee = calculateFee(tokensWithoutFee, buyFeePercentage);
    uint256 tokensWithFee = tokensWithoutFee - fee;
    _mint(msg.sender, tokensWithFee);
    _mint(address(this), fee);
  }

  function sell(uint256 tokenAmount) external nonReentrant {
    uint256 etherAmountWithoutFee = (tokenAmount * currentPrice) / 1e18;
    uint256 fee = calculateFee(etherAmountWithoutFee, sellFeePercentage);
    uint256 etherAmountWithFee = etherAmountWithoutFee - fee;
    require(address(this).balance >= etherAmountWithFee, "Insufficient ETH in contract");
    _burn(msg.sender, tokenAmount);
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
