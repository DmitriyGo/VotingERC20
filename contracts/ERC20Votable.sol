// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {VotingLinkedList, VotingData} from "./utils/VotingLinkedList.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC20.sol";

contract ERC20Votable is ERC20, AccessControl, ReentrancyGuard, VotingLinkedList {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  uint256 public constant MIN_PERCENTAGE_TO_INITIATE_VOTING = 1e15; // 0.1% in wei percentage
  uint256 public constant MIN_PERCENTAGE_TO_VOTE = 5e14; // 0.05% in wei percentage

  uint256 public timeToVote;
  uint256 public currentPrice;

  bool public isVotingActive;
  uint256 public votingStartTime;
  uint256 public votingEndTime;
  uint256 internal _votingRoundId;
  uint256 private _votingRoundLeadingPrice;
  mapping(uint256 => mapping(address => uint256)) _voterToPrice;

  event VotingStarted(uint256 indexed roundId, uint256 startTime, uint256 endTime);
  event VoteCast(uint256 indexed roundId, address indexed voter, uint256 price);
  event VotingEnded(uint256 indexed roundId, uint256 newPrice);

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 initialSupply,
    uint256 _timeToVote
  ) ERC20(name_, symbol_) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ADMIN_ROLE, msg.sender);

    _mint(msg.sender, initialSupply);
    timeToVote = _timeToVote;

    _votingRoundId = 1;
  }

  modifier voted() {
    require(
      _voterToPrice[_votingRoundId][msg.sender] != 0,
      "This feature is for users who have voted in this round, use the alternative method"
    );
    _;
  }

  modifier notVoted() {
    require(
      _voterToPrice[_votingRoundId][msg.sender] == 0,
      "This feature is for users who haven't voted in this round, use an alternative method"
    );
    _;
  }

  function startVoting(uint256 price) external {
    require(!isVotingActive, "Voting already active");
    require(
      balanceOf(msg.sender) >= (totalSupply() * MIN_PERCENTAGE_TO_INITIATE_VOTING) / 1e18,
      "Insufficient balance to initiate voting"
    );

    isVotingActive = true;
    votingStartTime = block.timestamp;
    votingEndTime = block.timestamp + timeToVote;

    _castVote(msg.sender, price, bytes32(0));

    emit VotingStarted(_votingRoundId, votingStartTime, votingEndTime);
  }

  function _castVote(address voter, uint256 price, bytes32 previousId) internal {
    require(isVotingActive, "No active voting session");
    require(balanceOf(voter) >= (totalSupply() * MIN_PERCENTAGE_TO_VOTE) / 1e18, "Insufficient balance to vote");
    require(_voterToPrice[_votingRoundId][voter] == 0, "Already voted");
    require(price > 0, "Price must be positive number");

    uint256 tokenAmount = balanceOf(voter);
    insert(_votingRoundId, price, tokenAmount, previousId);
    _voterToPrice[_votingRoundId][voter] = price;
    traverse();

    emit VoteCast(_votingRoundId, voter, price);
  }

  function castVote(uint256 price, bytes32 previousId) external {
    _castVote(msg.sender, price, previousId);
  }

  function endVote() external onlyRole(ADMIN_ROLE) {
    require(isVotingActive, "No active voting session");
    require(block.timestamp >= votingEndTime, "Voting period has not ended");

    VotingData memory leadingData = getById(getId(_votingRoundId, _votingRoundLeadingPrice));
    currentPrice = leadingData.price;

    isVotingActive = false;
    votingStartTime = 0;
    votingEndTime = 0;
    _votingRoundLeadingPrice = 0;

    _votingRoundId++;
    clear();

    emit VotingEnded(_votingRoundId, currentPrice);
  }

  function grantAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(ADMIN_ROLE, account);
  }

  function revokeAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(ADMIN_ROLE, account);
  }
}
