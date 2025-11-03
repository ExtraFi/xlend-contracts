// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

library Errors {
  error Initialized();
  error NotCreatorSetterAdmin();
  error AccountImportNotEnabled();
  error AccountTypeNotEnabled();
  error AccountTypeNotFound();
  error AccountTypeNotMatch();
  error FactoryNotMatch();
  error ReachMaxAccountTypes();
  error ReachMaxTotalAccounts();
  error ReachMaxAccountsOfType();
  error AccountCreatorNotSet();
  error IndexStartMustBeLessThanEnd();
  error IndexOutOfBounds();
  error AccountCreateFailed();
  error OnlyFactory();
  error InvalidAccountOwner();
  error ImplementationMismatch();
  error AccountAddressNotMatch();
}
