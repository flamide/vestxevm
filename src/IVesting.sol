// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVesting {
    enum Pause {
        Unpaused,
        Paused
    }

    function factory() external view returns (address);
    function admin() external view returns (address);
    function pause() external view returns (Pause);
    function rateBps() external view returns (uint256);
    function banUser(address _user) external view returns (bool);
    function isVestingCreated(uint8 categoryId) external view returns (bool);

    function createCategory(uint8 _categoryId, uint256 _rate, uint256 _totalVestAmount) external;
    function createVesting(address _user, uint8 _categoryId) external;
    function blacklistUser(address _user, uint8 _categoryId) external;
    function toggleUser(address _user, uint8 _categoryId) external;
    function toggleVesting() external;
    function getTotalVest(address _user, uint8 _categoryId) external view returns (uint256);
    function vest(uint8 _categoryId) external;
    function balanceOf(address _account, uint256 _id) external view returns (uint256);

    function userData(address _user, uint8 _categoryId)
        external
        view
        returns (
            uint256 vestSnapshot,
            uint256 lastTimestamp,
            Pause pauseState,
            bool active
        );

    function category(uint8 _categoryId)
        external
        view
        returns (
            uint256 rate,
            uint256 totalVestAmount,
            uint256 firstTimestamp,
            bool isCreated
        );

    event CategoryCreated(uint8 indexed categoryId, uint256 rate, uint256 totalVestAmount);
    event VestingCreated(address indexed user, uint8 indexed categoryId, uint256 initializedAmount);
    event TokensVested(address indexed user, uint8 indexed categoryId, uint256 amountClaimed);
    event UserBlacklisted(address indexed user);
    event UserTogglePaused(address indexed user, bool isPaused);
    event ProtocolTogglePaused(bool isPaused);
}
