// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import './Helpers.sol';
import '../interfaces/ICoinbaseSmartAccount.sol';
import '../interfaces/ISafeSmartAccount.sol';

library AccountCreatorDeprecated {
  // EXTRA_X_ACCOUNT_SEED = keccak256(abi.encode("EXTRA_X_ACCOUNT"));
  bytes32 public constant EXTRA_X_ACCOUNT_SEED =
    0x6efab0c0760c5fc7c871ea70acc1e04eac1c4c0e516b114fcd3302fc485b62bc;

  address public constant SAFE_PROXY_FACTORY_L2 = 0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC;
  address public constant SAFE_SINGLETON_L2 = 0xfb1bffC9d739B8D520DaF37dF666da4C687191EA;

  address public constant COINBASE_ACCOUNT_PROXY_FACTORY =
    0x0BA5ED0c6AA8c49038F819E587E2633c4A9F428a;

  function ACCOUNT_NONCE(uint8 accType, address owner, uint256 id) internal view returns (uint256) {
    return uint256(keccak256(abi.encode(address(this), EXTRA_X_ACCOUNT_SEED, accType, owner, id)));
  }

  function validateAccountOwner(uint8 accType, address owner, address account) external view {
    if (accType == Helpers.ACCOUNT_TYPE_SAFE_1_3_0) {
      require(ISafeSmartAccount(account).isOwner(owner), 'owner!');
    } else if (accType == Helpers.ACCOUNT_TYPE_COINBASE) {
      require(ICoinbaseSmartAccount(account).isOwnerAddress(owner), 'owner!');
    } else {
      revert('acc_t!');
    }
  }

  function createAccount(uint8 accType, address owner, uint256 id) external returns (address) {
    if (accType == Helpers.ACCOUNT_TYPE_SAFE_1_3_0) {
      return createSafeAccount_1_3_0(owner, id);
    } else if (accType == Helpers.ACCOUNT_TYPE_COINBASE) {
      return createCoinbaseSmartAccount(owner, id);
    } else {
      revert('acc_t!');
    }
  }

  function createSafeAccount_1_3_0(address owner, uint256 id) internal returns (address account) {
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

    account = IGnosisSafeProxyFactory(SAFE_PROXY_FACTORY_L2).createProxyWithNonce(
      SAFE_SINGLETON_L2,
      initializer,
      ACCOUNT_NONCE(Helpers.ACCOUNT_TYPE_SAFE_1_3_0, owner, id)
    );
  }

  function createCoinbaseSmartAccount(
    address owner,
    uint256 id
  ) internal returns (address account) {
    bytes[] memory _owners = new bytes[](1);
    _owners[0] = abi.encode(owner);

    account = address(
      ICoinbaseSmartAccountFactory(COINBASE_ACCOUNT_PROXY_FACTORY).createAccount(
        _owners,
        ACCOUNT_NONCE(Helpers.ACCOUNT_TYPE_COINBASE, owner, id)
      )
    );
  }
}
