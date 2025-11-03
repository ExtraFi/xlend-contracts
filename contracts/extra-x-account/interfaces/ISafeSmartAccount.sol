// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ISafeSmartAccount {
  function setup(
    address[] calldata _owners,
    uint256 _threshold,
    address to,
    bytes calldata data,
    address fallbackHandler,
    address paymentToken,
    uint256 payment,
    address payable paymentReceiver
  ) external;

  function isOwner(address owner) external view returns (bool);
  function getOwners() external view returns (address[] memory);
  function getThreshold() external view returns (uint256);
  function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);
}

interface IGnosisSafeProxyFactory {
  function createProxyWithNonce(
    address _singleton,
    bytes memory initializer,
    uint256 saltNonce
  ) external returns (address account);

  function calculateCreateProxyWithNonceAddress(
    address _singleton,
    bytes calldata initializer,
    uint256 saltNonce
  ) external view returns (address proxy);

  function proxyCreationCode() external view returns (bytes memory);
}
