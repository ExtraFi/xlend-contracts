// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

library Helpers {
  uint8 public constant ACCOUNT_TYPE_SAFE_1_3_0 = 0;
  uint8 public constant ACCOUNT_TYPE_COINBASE = 1;

  // EXTRA_X_ACCOUNT_SEED = keccak256(abi.encode("EXTRA_X_ACCOUNT"));
  bytes32 public constant EXTRA_X_ACCOUNT_SEED =
    0x6efab0c0760c5fc7c871ea70acc1e04eac1c4c0e516b114fcd3302fc485b62bc;

  /// @notice Returns the nonce for an account.
  /// @param factory The factory address.
  /// @param accType The type of account.
  /// @param owner The owner of the account.
  /// @param id The id of the account.
  /// @return The nonce for the account.  
  function ACCOUNT_NONCE(address factory, uint8 accType, address owner, uint256 id) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(factory, EXTRA_X_ACCOUNT_SEED, accType, owner, id)));
  }
}
