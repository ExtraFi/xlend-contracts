// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import '../core-v3/dependencies/openzeppelin/contracts/AccessControl.sol';
import '../core-v3/dependencies/openzeppelin/contracts/Address.sol';
import './interfaces/IAccountCreator.sol';
import './interfaces/IExtraXAccountFactory.sol';
import './libraries/Errors.sol';


contract ExtraXAccountFactory is IExtraXAccountFactory, AccessControl {
  // Maximum number of account types
  uint256 public constant MAX_ACCOUNT_TYPES = 64;

  // Maximum number of accounts per user
  uint256 public constant MAX_TOTAL_ACCOUNTS_PER_USER = 512;

  // Maximum number of accounts of a single type per user
  uint256 public constant MAX_ACCOUNTS_OF_TYPE_PER_USER = 64;

  // admin role have permission to set account creator
  bytes32 public constant ROLE_CREATOR_SETTER = keccak256('ROLE_CREATOR_SETTER');

  // initialized
  uint8 public initialized;

  // is account import enabled
  bool public isAccountImportEnabled;

  // total account types
  uint8 public totalAccTypes;

  // accType => enabled
  mapping(uint8 => bool) public accountTypeEnabled;

  // accType => accountCreator
  mapping(uint8 => address) public accountCreators;

  // owner => accType => nextCreateAccountId
  mapping(address => mapping(uint8 => uint256)) public nextCreateAccountId;

  // owner => accType => nextImportedAccountId
  mapping(address => mapping(uint8 => uint256)) public nextImportedAccountId;

  // user total accounts
  mapping(address => uint256) public userTotalAccounts;

  // owner => (accountId => ExtraAccount)
  mapping(address => mapping(uint256 => ExtraAccount)) public accountsOfOwner;

  // account => ExtraAccount
  mapping(address => ExtraAccount) public accountInfo;

  modifier onlyAccountImportEnabled() {
    if (!isAccountImportEnabled) {
      revert Errors.AccountImportNotEnabled();
    }
    _;
  }

  modifier onlyEnabledAccType(uint8 accType) {
    if (!accountTypeEnabled[accType]) {
      revert Errors.AccountTypeNotEnabled();
    }
    _;
  }

  modifier onlyCreatorSetter() {
    if (!hasRole(ROLE_CREATOR_SETTER, msg.sender)) {
      revert Errors.NotCreatorSetterAdmin();
    }
    _;
  }

  modifier initializable() {
    if (initialized != 0) {
      revert Errors.Initialized();
    }
    _;
  }

  constructor(address admin) {
    initialize(admin);
  }

  function initialize(address admin) public initializable {
    initialized = 1;

    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(ROLE_CREATOR_SETTER, admin);

    emit AccountFactoryInitialized(admin);
  }

  // enable account import
  // only admin can enable account import
  function enableAccountImport() public onlyCreatorSetter {
    isAccountImportEnabled = true;

    emit AccountImportEnabled(true);
  }

  // disable account import
  // only admin can disable account import
  function disableAccountImport() public onlyCreatorSetter {
    isAccountImportEnabled = false;

    emit AccountImportEnabled(false);
  }

  // enable an account type
  // only admin can enable an account type
  function enableAccType(uint8 accType) public onlyCreatorSetter {
    require(accType < totalAccTypes, 'acc_t not exist!');

    accountTypeEnabled[accType] = true;

    emit AccountTypeEnabled(accType, true);
  }

  // disable an account type
  // only admin can disable an account type
  function disableAccType(uint8 accType) public onlyCreatorSetter {
    require(accType < totalAccTypes, 'acc_t not exist!');

    accountTypeEnabled[accType] = false;

    emit AccountTypeEnabled(accType, false);
  }

  // update account creator for a already existing account type
  // only admin can update account creator for a already existing account type
  function updateAccountCreator(
    uint8 accType,
    address creator,
    bool enabled
  ) external onlyCreatorSetter {
    if (accType >= totalAccTypes) {
      revert Errors.AccountTypeNotFound();
    }

    if (accType != IAccountCreator(creator).ACCOUNT_TYPE()) {
      revert Errors.AccountTypeNotMatch();
    }

    if (IAccountCreator(creator).factory() != address(this)) {
      revert Errors.FactoryNotMatch();
    }

    address oldCreator = accountCreators[accType];
    accountCreators[accType] = creator;

    if (enabled) {
      enableAccType(accType);
    } else {
      disableAccType(accType);
    } 

    emit AccountCreatorUpdated(accType, oldCreator, creator, msg.sender);
  }

  // add a new account type
  // only admin can add a new account type  
  function addAccountCreator(address creator, bool enabled) external onlyCreatorSetter {
    uint8 accType = totalAccTypes;
    if (accType >= MAX_ACCOUNT_TYPES) {
      revert Errors.ReachMaxAccountTypes();
    }

    if (accType != IAccountCreator(creator).ACCOUNT_TYPE()) {
      revert Errors.AccountTypeNotMatch();
    }

    if (IAccountCreator(creator).factory() != address(this)) {
      revert Errors.FactoryNotMatch();
    }

    accountCreators[accType] = creator;
    totalAccTypes++;

    if (enabled) {
      enableAccType(accType);
    }

    emit AccountCreatorUpdated(accType, address(0), creator, msg.sender);
  }

  function getAccountCreator(uint8 accType) public view returns (address accountCreator) {
    if (accType >= totalAccTypes) {
      revert Errors.AccountTypeNotFound();
    }

    accountCreator = accountCreators[accType];
    if (accountCreator == address(0)) {
      revert Errors.AccountCreatorNotSet();
    }
  }

  function getAccountsOfOwner(address owner) public view returns (ExtraAccount[] memory) {
    uint256 total = userTotalAccounts[owner];

    ExtraAccount[] memory accounts = new ExtraAccount[](total);

    for (uint i = 0; i < total; ++i) {
      accounts[i] = accountsOfOwner[owner][i];
    }

    return accounts;
  }

  function getAccountsOfOwnerByIndex(address owner, uint256 start, uint256 end) public view returns (ExtraAccount[] memory) {
    if (start >= end) {
      revert Errors.IndexStartMustBeLessThanEnd();
    }

    if (end > userTotalAccounts[owner]) {
      revert Errors.IndexOutOfBounds();
    }

    ExtraAccount[] memory accounts = new ExtraAccount[](end - start);

    for (uint i = start; i < end; ++i) {
      accounts[i-start] = accountsOfOwner[owner][i];
    }

    return accounts;
  }

  // preview the account address and id before creating an account
  function previewCreateAccount(uint8 accType, address owner) public onlyEnabledAccType(accType) view returns (address account, uint256 id) {
    id = nextCreateAccountId[owner][accType];
    address accountCreator = getAccountCreator(accType);
    return (IAccountCreator(accountCreator).calculateAccountAddress(accType, owner, id), id);
  }

  function createAccount(uint8 accType) public onlyEnabledAccType(accType) returns (address account, uint256 id) {
    (account, id) = createAccountFor(accType, msg.sender);
  }

  function createAccountFor(uint8 accType, address owner) public onlyEnabledAccType(accType) returns (address account, uint256 id) {
    id = nextCreateAccountId[owner][accType];
    if (id >= MAX_ACCOUNTS_OF_TYPE_PER_USER) {
      revert Errors.ReachMaxAccountsOfType();
    }

    address accountCreator = getAccountCreator(accType);

    address calcAccountAddr = IAccountCreator(accountCreator).calculateAccountAddress(accType, owner, id);  
    if (calcAccountAddr.code.length > 0) {
        // Account creation is open, allowing anyone to create an account based on the address 
        // generation rules using other factories. If an account has already been created using the same rules, 
        // it can be registered as an created account within this Factory if the account owner is valid.  
        account = calcAccountAddr;
        IAccountCreator(accountCreator).validateAccountOwner(accType, owner, account);
    } else {
        // create a new account
        account = IAccountCreator(accountCreator).createAccount(accType, owner, id);
        if (account != calcAccountAddr){
            revert Errors.AccountAddressNotMatch();
        }
    }

    uint256 userTotal = userTotalAccounts[owner];
    if (userTotal >= MAX_TOTAL_ACCOUNTS_PER_USER) {
      revert Errors.ReachMaxTotalAccounts();
    }

    accountsOfOwner[owner][userTotal] = ExtraAccount(account, accType, id, false);
    accountInfo[account] = accountsOfOwner[owner][userTotal];

    userTotalAccounts[owner] = userTotal + 1;
    nextCreateAccountId[owner][accType] = id + 1;

    emit AccountCreated(owner, account, accType, id);
  }

  function importAccount(uint8 accType, address account) onlyAccountImportEnabled onlyEnabledAccType(accType) public returns (uint256 id) {
    address owner = msg.sender;

    id = nextImportedAccountId[owner][accType];
    if (id >= MAX_ACCOUNTS_OF_TYPE_PER_USER) {
      revert Errors.ReachMaxAccountsOfType();
    }

    address accountCreator = getAccountCreator(accType);

    IAccountCreator(accountCreator).validateAccountOwner(accType, owner, account);

    uint256 userTotal = userTotalAccounts[owner];
    if (userTotal >= MAX_TOTAL_ACCOUNTS_PER_USER) {
      revert Errors.ReachMaxTotalAccounts();
    }

    accountsOfOwner[owner][userTotal] = ExtraAccount(account, accType, id, true);
    accountInfo[account] = accountsOfOwner[owner][userTotal];

    userTotalAccounts[owner] = userTotal + 1;
    nextImportedAccountId[owner][accType] = id + 1;

    emit AccountImported(owner, account, accType, id);
  }
}
