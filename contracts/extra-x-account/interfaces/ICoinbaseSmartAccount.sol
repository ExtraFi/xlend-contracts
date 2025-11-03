// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {UserOperation} from "../dependencies/account-abstraction/contracts/interfaces/UserOperation.sol";

interface ICoinbaseSmartAccountFactory {
    function implementation() external view returns (address);

    /// @notice Returns the deterministic address for a CoinbaseSmartWallet created with `owners` and `nonce`
    ///         deploys and initializes contract if it has not yet been created.
    ///
    /// @dev Deployed as a ERC-1967 proxy that's implementation is `this.implementation`.
    ///
    /// @param owners Array of initial owners. Each item should be an ABI encoded address or 64 byte public key.
    /// @param nonce  The nonce of the account, a caller defined value which allows multiple accounts
    ///               with the same `owners` to exist at different addresses.
    ///
    /// @return account The address of the ERC-1967 proxy created with inputs `owners`, `nonce`, and
    ///                 `this.implementation`.
    function createAccount(bytes[] calldata owners, uint256 nonce)
        external
        payable
        returns (ICoinbaseSmartAccount account);

    /// @notice Returns the deterministic address of the account that would be created by `createAccount`.
    /// @param owners Array of initial owners. Each item should be an ABI encoded address or 64 byte public key.
    /// @param nonce  The nonce provided to `createAccount()`.
    ///
    /// @return The predicted account deployment address.
    function getAddress(bytes[] calldata owners, uint256 nonce) external view returns (address);
}

interface ICoinbaseSmartAccount {
    function implementation() external view returns (address);
    function isOwnerAddress(address account) external view returns (bool);
    function isOwnerPublicKey(bytes32 x, bytes32 y) external view returns (bool);
    function isOwnerBytes(bytes memory account) external view returns (bool);
    function removeOwnerAtIndex(uint256 index, bytes calldata owner) external;

    /// @notice A wrapper struct used for signature validation so that callers
    ///         can identify the owner that signed.
    struct SignatureWrapper {
        /// @dev The index of the owner that signed, see `MultiOwnable.ownerAtIndex`
        uint256 ownerIndex;
        /// @dev If `MultiOwnable.ownerAtIndex` is an Ethereum address, this should be `abi.encodePacked(r, s, v)`
        ///      If `MultiOwnable.ownerAtIndex` is a public key, this should be `abi.encode(WebAuthnAuth)`.
        bytes signatureData;
    }

    /// @notice Represents a call to make.
    struct Call {
        /// @dev The address to call.
        address target;
        /// @dev The value to send when making the call.
        uint256 value;
        /// @dev The data of the call.
        bytes data;
    }

    ////  @inheritdoc IAccount
    ///
    /// @notice ERC-4337 `validateUserOp` method. The EntryPoint will
    ///         call `UserOperation.sender.call(UserOperation.callData)` only if this validation call returns
    ///         successfully.
    ///
    /// @dev Signature failure should be reported by returning 1 (see: `this._isValidSignature`). This
    ///      allows making a "simulation call" without a valid signature. Other failures (e.g. invalid signature format)
    ///      should still revert to signal failure.
    /// @dev Reverts if the `UserOperation.nonce` key is invalid for `UserOperation.calldata`.
    /// @dev Reverts if the signature format is incorrect or invalid for owner type.
    ///
    /// @param userOp              The `UserOperation` to validate.
    /// @param userOpHash          The `UserOperation` hash, as computed by `EntryPoint.getUserOpHash(UserOperation)`.
    /// @param missingAccountFunds The missing account funds that must be deposited on the Entrypoint.
    ///
    /// @return validationData The encoded `ValidationData` structure:
    ///                        `(uint256(validAfter) << (160 + 48)) | (uint256(validUntil) << 160) | (success ? 0 : 1)`
    ///                        where `validUntil` is 0 (indefinite) and `validAfter` is 0.
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData);

    /// @notice Executes `calls` on this account (i.e. self call).
    ///
    /// @dev Can only be called by the Entrypoint.
    /// @dev Reverts if the given call is not authorized to skip the chain ID validtion.
    /// @dev `validateUserOp()` will recompute the `userOpHash` without the chain ID before validating
    ///      it if the `UserOperation.calldata` is calling this function. This allows certain UserOperations
    ///      to be replayed for all accounts sharing the same address across chains. E.g. This may be
    ///      useful for syncing owner changes.
    ///
    /// @param calls An array of calldata to use for separate self calls.
    function executeWithoutChainIdValidation(bytes[] calldata calls) external payable;

    /// @notice Executes the given call from this account.
    ///
    /// @dev Can only be called by the Entrypoint or an owner of this account (including itself).
    ///
    /// @param target The address to call.
    /// @param value  The value to send with the call.
    /// @param data   The data of the call.
    function execute(address target, uint256 value, bytes calldata data) external payable;

    /// @notice Executes batch of `Call`s.
    ///
    /// @dev Can only be called by the Entrypoint or an owner of this account (including itself).
    ///
    /// @param calls The list of `Call`s to execute.
    function executeBatch(Call[] calldata calls) external payable;

    /// @notice Returns the address of the EntryPoint v0.6.
    ///
    /// @return The address of the EntryPoint v0.6
    function entryPoint() external view returns (address);

    /// @notice Computes the hash of the `UserOperation` in the same way as EntryPoint v0.6, but
    ///         leaves out the chain ID.
    ///
    /// @dev This allows accounts to sign a hash that can be used on many chains.
    ///
    /// @param userOp The `UserOperation` to compute the hash for.
    ///
    /// @return The `UserOperation` hash, which does not depend on chain ID.
    function getUserOpHashWithoutChainId(UserOperation calldata userOp) external view returns (bytes32);

    /// @notice Returns whether `functionSelector` can be called in `executeWithoutChainIdValidation`.
    ///
    /// @param functionSelector The function selector to check.
    /// @return `true` is the function selector is allowed to skip the chain ID validation, else `false`.
    function canSkipChainIdValidation(bytes4 functionSelector) external pure returns (bool);
}
