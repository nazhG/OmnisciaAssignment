// SPDX-License-Identifier: MIT

/** solc version is too old and too ambiguous */
// pragma solidity >=0.4.22 <0.9.0;
pragma solidity ^0.8.0;

contract Migrations {
  // owner should mark as immutable and inicialize in constructor
  address public immutable owner;
  // recomended follow the naming convention
  /** https://docs.soliditylang.org/en/v0.4.25/style-guide.html#local-and-state-variable-names */
  uint public lastCompletedMigration;

  constructor() {
    owner = msg.sender;
  }

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  /** this function should be declared external */
  function setCompleted(uint completed) external restricted {
    lastCompletedMigration = completed;
  }
}
