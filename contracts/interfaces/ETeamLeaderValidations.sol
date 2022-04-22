// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../libraries/employee.sol";
import "../libraries/factory.sol";
import "../teamLeader.sol";

abstract contract ETeamLeaderValidations is
    Initializable,
    Context,
    AccessControl
{
    struct XPReward {
        EmployeeLibrary.EmployeeNFT employee;
        EmployeeLibrary.EmployeeChildrenNFT miniEmployee;
        FactoryLibrary.FactoryNFT factory;
        EmployeeLibrary.EmployeeNFT multiEmployee;
        uint256 level;
    }

    struct XPRewardsInfo {
        XPReward rewards;
        bool canRequest;
    }

    struct Incrementation {
        uint256 id;
        uint256 totalXP;
        uint256 level;
        uint256 nextLevel;
        uint256 time;
    }

    struct TeamLeaderInfo {
        TeamLeaderNFT.TeamLeaderData teamLeader;
        uint256 maxMultiplier;
        bool inBlacklist;
    }

    event IncreaseXP(Incrementation);
    event MintLeader(address owner, uint256 time);

    bytes32 public constant LINK = keccak256("LINK");
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_LEADER = "CR: Invalid leader";
    string public constant INVALID_OWNER = "CR: Invalid owner";
    string public constant BLACK_LISTED = "CR: Black listed";
    string public constant INVALID_REWARDS = "CR: Invalid rewards";

    uint8[] public validMultiplicators = [
        1,
        2,
        3,
        4,
        6,
        8,
        12,
        14,
        16,
        20,
        22,
        24,
        26,
        28,
        30,
        33,
        36,
        39,
        42,
        45,
        48,
        51,
        54,
        57,
        60,
        63,
        66,
        69,
        72,
        75,
        78,
        81,
        84,
        87,
        90,
        93,
        96,
        99,
        101,
        104
    ];

    mapping(uint256 => XPReward) internal rewards;
    mapping(address => mapping(uint256 => bool)) internal rewardsRequests;
    mapping(uint256 => bool) internal blackList; // TeamLeader => validation

    uint256 totalRewards = 0;

    function getReward(uint256) external view virtual returns (XPReward memory);

    function getRewardInfo(uint256, address)
        external
        view
        virtual
        returns (XPRewardsInfo memory);

    function getRewards() external view virtual returns (XPReward[] memory);

    function updateRewardRequest(address, uint256, bool) external virtual;

    function getRewardsInfo(address)
        external
        view
        virtual
        returns (XPRewardsInfo[] memory);

    function canRequestRewards(uint256, address)
        public
        view
        virtual
        returns (bool);

    function updateTotalRewards(uint256) external virtual;

    function updateReward(
        uint256,
        EmployeeLibrary.EmployeeNFT calldata employee,
        EmployeeLibrary.EmployeeChildrenNFT calldata miniEmployee,
        FactoryLibrary.FactoryNFT calldata factory,
        EmployeeLibrary.EmployeeNFT calldata multiEmployee,
        uint256
    ) external virtual;

    function requestRewards(uint256) external virtual;

    function getMaxMultiplicator(address _owner)
        public
        view
        virtual
        returns (uint8);

    function getTeamLeaderInfo()
        external
        view
        virtual
        returns (TeamLeaderInfo memory);

    function isInBlackList(uint256 _id) public view virtual returns (bool);

    function mintLeader() external virtual;

    function addXPToOwner(address _owner, uint256 _xp) external virtual;

    function addToBlacklist(uint256 _id, bool _state) external virtual;

    function updateAddresses(
        address _employees,
        address _miniEmployees,
        address _factories,
        address _multiEmployees,
        address _teamLeader
    ) external virtual;
}
