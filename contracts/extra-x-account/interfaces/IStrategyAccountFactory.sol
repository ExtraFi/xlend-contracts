// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IStrategyAccountFactory {
    struct StrategyAccount {
        address account;
        address user;
        address opener;
        uint256 id;
        uint48 createdAt;
        bool active;
        string tag;
    }

    event StrategyAccountCreated(address indexed user, address indexed opener, address account, uint256 id, string tag);

    event StrategyAccountStatusUpdated(address indexed account, bool active);

    event StrategyAccountOwnerSynced(address indexed account, address indexed previousUser, address indexed newUser);

    event OpenerAuthorizationUpdated(address indexed opener, bool authorized);

    event DevModeUpdated(bool enabled);

    function createStrategyAccount(address user, address opener, string calldata tag)
        external
        returns (address account, uint256 id);

    function getAccountsOfOwner(address user) external view returns (address[] memory);

    function getActiveAccountsOfOwner(address user) external view returns (address[] memory);

    function getAccountInfo(address account) external view returns (StrategyAccount memory);

    function previewStrategyAccounts(address user, uint256[] calldata ids) external view returns (address[] memory);

    function syncAccountOwner(address account, address newUser) external;

    function markAccountInactive(address account) external;

    function setAuthorizedOpener(address opener, bool authorized) external;

    function updateDevMode(bool enabled) external;
}
