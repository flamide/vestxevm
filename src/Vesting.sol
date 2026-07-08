// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Vesting is ERC1155 {

    address public factory;
    address public admin;

    mapping(address => bool) public banUser;

    Pause public pause;
    uint256 immutable public PROTOCOL_ID;

    uint256 public rateBps;

    
    mapping(address => mapping(uint8 => UserData)) public userData;
    mapping(uint8 => CategoryData) public category;

    enum Pause {
        Unpaused,
        Paused
    }

    struct UserData {
        uint256 vestSnapshot;
        uint256 lastTimestamp;
        Pause pause;
        bool active;
    }

    struct CategoryData {
        uint256 rate;
        uint256 totalVestAmount;
        uint256 firstTimestamp;
        bool isCreated;
    }

    
    error NotAdmin();
    error ProtocolPaused();
    error UserIsBanned();
    error UserIsPaused();
    error CategoryDoesNotExist();
    error CategoryAlreadyExists();
    error AlreadyRegistered();
    error NothingToClaim();
    error VestingLimitExceeded();

    event CategoryCreated(uint8 indexed categoryId, uint256 rate, uint256 totalVestAmount);
    // Modified to track the specific plan categorization index
    event VestingCreated(address indexed user, uint8 indexed categoryId, uint256 initializedAmount);
    event TokensVested(address indexed user, uint8 indexed categoryId, uint256 amountClaimed);
    event UserBlacklisted(address indexed user);
    event UserTogglePaused(address indexed user, bool isPaused);
    event ProtocolTogglePaused(bool isPaused);

    modifier checkAdmin() {
        _checkAdmin();
        _;
    }

    modifier whenNotPaused() {
        _checkNotPaused();
        _;
    }

    constructor(uint256 _protocolId, address _factory, address _admin)
        ERC1155("Vestingtokens") 
    {
        PROTOCOL_ID = _protocolId;
        factory = _factory;
        admin = _admin;
        pause = Pause.Unpaused;
    }

    /**
     * @notice Admin creates a new specific structural tier arrangement plan
     */
    function createCategory(uint8 _categoryId, uint256 _rate, uint256 _totalVestAmount) external checkAdmin {
        if (category[_categoryId].isCreated) revert CategoryAlreadyExists();

        category[_categoryId] = CategoryData({
            rate: _rate / rateBps, 
            totalVestAmount: _totalVestAmount,
            firstTimestamp: block.timestamp,
            isCreated: true
        });

        emit CategoryCreated(_categoryId, _rate, _totalVestAmount);
    }

    /**
     * @notice Registers a user target for a specific configuration asset plan line
     */
    function createVesting(address _user, uint8 _categoryId) external checkAdmin {
        if (!category[_categoryId].isCreated) revert CategoryDoesNotExist();
        if (banUser[_user]) revert UserIsBanned();
        
        // Prevent accidental overwriting of initialized user profiles
        if (balanceOf(_user, _categoryId) > 0 || userData[_user][_categoryId].lastTimestamp != 0) {
            revert AlreadyRegistered();
        }

        CategoryData memory targetPlan = category[_categoryId];

        // Setup the initial time sequence configuration
        userData[_user][_categoryId] = UserData({
            vestSnapshot: 0,
            lastTimestamp: targetPlan.firstTimestamp,
            pause: Pause.Unpaused,
            active: true
        });

        // Initialize mapping balances natively leveraging your standard ERC1155 engine properties
        _mint(_user, _categoryId, 0, "");//@audit we are minting 0 at first

        emit VestingCreated(_user, _categoryId, targetPlan.totalVestAmount);
    }

    /**
     * @notice Completely burn all distribution privileges held by toxic or bad-acting accounts
     */
    function blacklistUser(address _user, uint8 _categoryId) external checkAdmin {
        banUser[_user] = true;
        uint256 currentBalance = balanceOf(_user, _categoryId);
        
        if (currentBalance > 0) {//@audit this should be emphasised on
            _burn(_user, _categoryId, currentBalance);
        }

        emit UserBlacklisted(_user);
    }

    /**
     * @notice Toggles freezing individual target address streams
     */
    function toggleUser(address _user, uint8 _categoryId) external checkAdmin {
        UserData storage user = userData[_user][_categoryId];
        
        if (user.pause == Pause.Unpaused) {
            user.pause = Pause.Paused;
            emit UserTogglePaused(_user, true);
        } else {
            user.pause = Pause.Unpaused;
            emit UserTogglePaused(_user, false);
        }
    }

    /**
     * @notice Emergency multi-asset switch to stop global operations
     */
    function toggleVesting() external checkAdmin {
        if (pause == Pause.Unpaused) {
            pause = Pause.Paused;
            emit ProtocolTogglePaused(true);
        } else {
            pause = Pause.Unpaused;
            emit ProtocolTogglePaused(false);
        }
    }

    /**
     * @notice Calculates real-time total active claimable token units generated at the current block height
     */
    function getTotalVest(address _user, uint8 _categoryId) public view returns (uint256) {
        if (!category[_categoryId].isCreated) return 0;
        
        UserData memory user = userData[_user][_categoryId];
        if(!user.active) return 0;

        CategoryData memory plan = category[_categoryId];

        uint256 timeDelta = user.lastTimestamp == 0 ? block.timestamp - plan.firstTimestamp : user.lastTimestamp;        
        
        // Multiplied by total starting layout value allocations tracked on raw mapping slots
        uint256 accrued = timeDelta * plan.rate * plan.totalVestAmount;
        uint256 totalVested = user.vestSnapshot + accrued;//@audit we dont need the totalwithdrawn state

        return totalVested;
    }

    /**
     * @notice Core execution point for users trying to process claims down to their wallets
     */
    function vest(uint8 _categoryId) external whenNotPaused {
        if (banUser[msg.sender]) revert UserIsBanned();
        if (userData[msg.sender][_categoryId].pause == Pause.Paused) revert UserIsPaused();
        if (!category[_categoryId].isCreated) revert CategoryDoesNotExist();

        uint256 claimableAmount = getTotalVest(msg.sender, _categoryId);
        if (claimableAmount == 0) revert NothingToClaim();

        UserData storage user = userData[msg.sender][_categoryId];
        CategoryData memory plan = category[_categoryId];

        // Safety checks to ensure we never over-allocate tracking distributions
        uint256 absoluteRemanent = plan.totalVestAmount - user.vestSnapshot;
        if (claimableAmount > absoluteRemanent) {
            claimableAmount = absoluteRemanent;
        }

        // Update tracking configurations prior to state distribution lines
        user.vestSnapshot += claimableAmount;
        user.lastTimestamp = block.timestamp;

        // Use the native safeTransfer ERC1155 processing route to pass underlying items
        // In production implementation contexts, this line typically calls an external asset interface contract.
        // For standard self-contained mechanics, we transfer the ERC1155 token asset weight down to the receiver wallet.
        _safeTransferFrom(msg.sender, address(this), _categoryId, claimableAmount, "");

        emit TokensVested(msg.sender, _categoryId, claimableAmount);
    }

    function _checkAdmin() private view {
        if (msg.sender != admin) revert NotAdmin();
    }

    function _checkNotPaused() private view {
        if (pause == Pause.Paused) revert ProtocolPaused();
    }

    function isVestingCreated(uint8 categoryId) public view returns(bool) {
        return category[categoryId].isCreated;
    }
}
