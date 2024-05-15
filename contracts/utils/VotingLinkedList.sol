// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "hardhat/console.sol";

struct VotingData {
  uint256 price;
  uint256 amount;
}

struct Node {
  bytes32 previous;
  VotingData data;
  bytes32 next;
}

contract VotingLinkedList {
  event NodeAdded(bytes32 indexed id, uint256 price, uint256 amount);
  event NodeUpdated(bytes32 indexed id, uint256 newAmount);
  event NodeDeleted(bytes32 indexed id);
  event ListCleared();

  uint256 public length = 0;
  bytes32 public head;
  bytes32 public tail;
  mapping(bytes32 => Node) public list;

  function isEmpty() public view returns (bool) {
    return head == bytes32(0);
  }

  function getId(uint256 _votingId, uint256 _price) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_votingId, _price));
  }

  function getById(bytes32 id) public view returns (VotingData memory) {
    return list[id].data;
  }

  function getByPrice(uint256 _votingId, uint256 _price) public view returns (VotingData memory) {
    return list[getId(_votingId, _price)].data;
  }

  function _isNotEmpty(bytes32 id) internal view returns (bool) {
    return list[id].data.price != 0 && list[id].data.amount != 0;
  }

  function traverse() public view {
    bytes32 current = head;
    while (current != bytes32(0)) {
      console.logBytes32(current);
      console.log("Price: ", list[current].data.price);
      console.log("Amount: ", list[current].data.amount);
      current = list[current].next;
    }
    console.log("\n");
  }

  function insert(uint256 _votingId, uint256 _price, uint256 _amount, bytes32 previousId) public {
    bytes32 id = getId(_votingId, _price);
    if (_isNotEmpty(id)) {
      _deleteNode(id);
    }
    _insert(id, _price, _amount, previousId);
    emit NodeAdded(id, _price, _amount);
  }

  function _deleteNode(bytes32 id) private {
    require(!isEmpty(), "List is empty");
    require(list[id].data.price != 0, "Node does not exist");

    if (list[id].previous == bytes32(0)) {
      head = list[id].next;
    } else {
      list[list[id].previous].next = list[id].next;
    }

    if (list[id].next == bytes32(0)) {
      tail = list[id].previous;
    } else {
      list[list[id].next].previous = list[id].previous;
    }

    delete list[id];
    length--;
    emit NodeDeleted(id);
  }

  function clear() public {
    bytes32 current = head;
    while (current != bytes32(0)) {
      bytes32 toDelete = current;
      current = list[current].next;
      delete list[toDelete];
    }
    head = bytes32(0);
    tail = bytes32(0);
    length = 0;

    emit ListCleared();
  }

  function _insert(bytes32 id, uint256 _price, uint256 _amount, bytes32 previousId) private {
    require(_amount > 0, "Amount must be greater than 0");

    Node memory newNode = Node(bytes32(0), VotingData(_price, _amount), bytes32(0));

    if (isEmpty()) {
      head = id;
      tail = id;
    } else if (previousId == bytes32(0)) {
      require(_amount < list[head].data.amount, "Amount must be less than the head node amount");

      newNode.next = head;
      list[head].previous = id;
      head = id;
    } else {
      require(list[previousId].data.price > 0, "Invalid previousId");
      require(list[previousId].data.amount <= _amount, "Amount must be greater than the previous node amount");
      newNode.previous = previousId;
      newNode.next = list[previousId].next;

      if (list[previousId].next != bytes32(0)) {
        require(_amount < list[list[previousId].next].data.amount, "Amount must be less than the next node amount");
        list[list[previousId].next].previous = id;
      } else {
        tail = id;
      }

      list[previousId].next = id;
    }

    list[id] = newNode;
    length++;
    emit NodeAdded(id, _price, _amount);
  }
}
