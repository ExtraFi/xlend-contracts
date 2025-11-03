// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IAccountCreator {
  function ACCOUNT_TYPE() external view returns (uint8);
  function factory() external view returns (address);

  function calculateAccountAddress(uint8 accType, address owner, uint256 id) external view returns (address);
  function createAccount(uint8 accType, address owner, uint256 id) external returns (address);
  function validateAccountOwner(uint8 accType, address owner, address account) external view;
}
