// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import '../interfaces/IAccountCreator.sol';
import {ISafeSmartAccount, IGnosisSafeProxyFactory} from '../interfaces/ISafeSmartAccount.sol';
import {Helpers} from '../libraries/Helpers.sol';
import {GnosisSafeProxy} from '../dependencies/safe/contracts/GnosisSafeProxy.sol';
import {Errors} from '../libraries/Errors.sol';

contract SafeAccount130Creator is IAccountCreator {
  uint8 public constant ACCOUNT_TYPE = Helpers.ACCOUNT_TYPE_SAFE_1_3_0;

  address public constant SAFE_PROXY_FACTORY_L2 = 0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC;
  address public constant SAFE_SINGLETON_L2 = 0xfb1bffC9d739B8D520DaF37dF666da4C687191EA;

  address public immutable factory;
  address public immutable factorySalt;

  modifier onlyFactory() {
    if (msg.sender != factory) {
      revert Errors.OnlyFactory();
    }
    _;
  }

  constructor(address _factory) {
    factory = _factory;

    // factory salt is used to generate the account address, to get same address on different networks, we need to use same salt
    factorySalt = 0x90cF2763CC710B9Ce215584A89c77F70bbb96B44; 
  }

  function validateAccountOwner(uint8 accType, address owner, address account) external view {
    if(accType != ACCOUNT_TYPE) {
      revert Errors.AccountTypeNotMatch();
    }

    if(!ISafeSmartAccount(account).isOwner(owner)) {
      revert Errors.InvalidAccountOwner();
    }

    if(getSingleton(account) != SAFE_SINGLETON_L2) {
      revert Errors.ImplementationMismatch();
    }
  }

  function createAccount(uint8 accType, address owner, uint256 id) onlyFactory external returns (address account) {
    if(accType != ACCOUNT_TYPE) {
      revert Errors.AccountTypeNotMatch();
    }

    (address singleton, bytes memory initializer, uint256 saltNonce) = generateCreateAccountData(accType, owner, id);

    account = IGnosisSafeProxyFactory(SAFE_PROXY_FACTORY_L2).createProxyWithNonce(
      singleton,
      initializer,
      saltNonce
    );

    if(account == address(0)) {
      revert Errors.AccountCreateFailed();
    }
  }

  function calculateAccountAddress(uint8 accType, address owner, uint256 id) external view returns (address) {
    if(accType != ACCOUNT_TYPE) {
      revert Errors.AccountTypeNotMatch();
    }

    (address singleton, bytes memory initializer, uint256 saltNonce) = generateCreateAccountData(accType, owner, id);

    return calculateSafeAddress(
      singleton,
      initializer,
      saltNonce
    );
  }

  function calculateSafeAddress(
    address singleton,          
    bytes memory initializer,   
    uint256 saltNonce           
  ) public view returns (address) {
    // Hash the initializer and the saltNonce to get the salt
    bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));

    // Prepare the init_code: creationCode + uint256(singleton)
    bytes memory deploymentData = abi.encodePacked(
      IGnosisSafeProxyFactory(SAFE_PROXY_FACTORY_L2).proxyCreationCode(),
      uint256(uint160(singleton))
    );

    // Compute the init_code hash
    bytes32 initCodeHash = keccak256(deploymentData);

    // Compute the CREATE2 address
    return address(
      uint160(uint256(keccak256(abi.encodePacked(
        hex"ff",
        SAFE_PROXY_FACTORY_L2,
        salt, 
        initCodeHash
      ))))
    );
  }

  function generateCreateAccountData(uint8 accType, address owner, uint256 id) public view returns(address, bytes memory, uint256) {
    address[] memory _owners = new address[](1);
    _owners[0] = owner;

    bytes memory initializer = abi.encodeWithSelector(
      ISafeSmartAccount.setup.selector, // ACCOUNT_SETUP_METHOD_SELECTOR,
      _owners,
      1,
      address(0),
      bytes(''),
      address(0),
      address(0),
      0,
      payable(address(0))
    );

    return (SAFE_SINGLETON_L2, initializer, Helpers.ACCOUNT_NONCE(factorySalt, accType, owner, id));
  }

  function getSingleton(address account) public view returns (address) {
    bytes memory slotData = ISafeSmartAccount(account).getStorageAt(0, 1);
    bytes32 slot0Data = abi.decode(slotData, (bytes32));
    return address(uint160(uint256(slot0Data)));
  }
}
