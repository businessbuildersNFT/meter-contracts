// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract ETeamLeaderValidations is
    Initializable,
    Context,
    AccessControl
{
    event IncreaseXP(uint256 id, uint256 xpAddition, uint256 time);
    event MintLeader(address owner, uint256 time);

    bytes32 public constant LINK = keccak256("LINK");
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_LEADER = "CR: Invalid leader";

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

    mapping(uint256 => bool) internal blackList; // TeamLeader => validation

    function getMaxMultiplicator(address _owner)
        public
        view
        virtual
        returns (uint8);

    function isInBlackList(uint256 _id) public view virtual returns (bool);

    function mintLeader() external virtual;

    function addXPToOwner(address _owner, uint256 _xp) external virtual;

    function addToBlacklist(uint256 _id, bool _state) external virtual;

    function updateRegisterAddress(address _employees, address _teamLeader)
        external
        virtual;
}
