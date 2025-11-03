// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IExtraXAccountFactory {
  struct ExtraAccount {
    address account;
    uint8 accType;
    uint256 id;
    bool isImported;
  }

  event AccountFactoryInitialized(address indexed admin);

  event AccountImportEnabled(bool indexed enabled);

  event AccountTypeEnabled(
    uint8 indexed accType,
    bool indexed enabled
  );

  event AccountCreatorUpdated(
    uint8 indexed accType,
    address indexed oldCreator,
    address indexed newCreator,
    address setter
  );

  event AccountCreated(
    address indexed owner,
    address indexed account,
    uint8 indexed accType,
    uint256 id
  );

  event AccountImported(
    address indexed owner,
    address indexed account,
    uint8 indexed accType,
    uint256 id
  );

  function previewCreateAccount(uint8 accType, address owner) external view returns (address account, uint256 id);
  function createAccount(uint8 accType) external returns (address account, uint256 id);
  function importAccount(uint8 accType, address account) external returns (uint256 id);
}