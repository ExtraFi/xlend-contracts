// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import '../interfaces/IAccountCreator.sol';
import {ICoinbaseSmartAccountFactory, ICoinbaseSmartAccount} from '../interfaces/ICoinbaseSmartAccount.sol';
import {Helpers} from '../libraries/Helpers.sol';
import {Errors} from '../libraries/Errors.sol';

contract CoinbaseAccountCreator is IAccountCreator {
  uint8 public constant ACCOUNT_TYPE = Helpers.ACCOUNT_TYPE_COINBASE;

  // Changed from constant to immutable to support different addresses on different chains
  address public immutable coinbaseSmartWalletFactory;
  
  address public immutable factory;

  address public immutable factorySalt;

  constructor(address _factory, address _coinbaseSmartWalletFactory) {
    if (_coinbaseSmartWalletFactory == address(0)) {
      revert Errors.OnlyFactory(); // Reusing existing error for simplicity
    }
    
    factory = _factory;
    coinbaseSmartWalletFactory = _coinbaseSmartWalletFactory;
    // factory salt is used to generate the account address, to get same address on different networks, we need to use same salt
    factorySalt = 0x90cF2763CC710B9Ce215584A89c77F70bbb96B44;
  }

  modifier onlyFactory() {
    if (msg.sender != factory) {
      revert Errors.OnlyFactory();
    }
    _;
  }

  function validateAccountOwner(uint8 accType, address owner, address account) external view {
    if(accType != ACCOUNT_TYPE) {
      revert Errors.AccountTypeNotMatch();  
    }
    if(!ICoinbaseSmartAccount(account).isOwnerAddress(owner)) {
      revert Errors.InvalidAccountOwner();
    }
    if(ICoinbaseSmartAccount(account).implementation() != ICoinbaseSmartAccountFactory(coinbaseSmartWalletFactory).implementation()) {
      revert Errors.ImplementationMismatch();
    }
  }

  function createAccount(uint8 accType, address owner, uint256 id) onlyFactory external returns (address) {
    if (accType != ACCOUNT_TYPE) {
      revert Errors.AccountTypeNotMatch();
    }
    return createCoinbaseSmartAccount(accType, owner, id);
  }

  function createCoinbaseSmartAccount(
    uint8 accType,
    address owner,
    uint256 id
  ) internal returns (address account) {
    bytes[] memory _owners = new bytes[](1);
    _owners[0] = abi.encode(owner);

    uint256 nonce = Helpers.ACCOUNT_NONCE(factorySalt, accType, owner, id);

    account = address(
      ICoinbaseSmartAccountFactory(coinbaseSmartWalletFactory).createAccount(
        _owners,
        nonce
      )
    );

    if (account == address(0)) {
      revert Errors.AccountCreateFailed();
    }
  }

  function calculateAccountAddress(uint8 accType, address owner, uint256 id) external view returns (address) {
    bytes[] memory _owners = new bytes[](1);
    _owners[0] = abi.encode(owner);

    uint256 nonce = Helpers.ACCOUNT_NONCE(factorySalt, accType, owner, id);

    return ICoinbaseSmartAccountFactory(coinbaseSmartWalletFactory).getAddress(_owners, nonce);
  }
} 