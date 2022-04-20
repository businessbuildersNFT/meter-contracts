// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ETeamLeaderValidations.sol";
import "./employee.sol";
import "./teamLeader.sol";

contract TeamLeaderValidations is ETeamLeaderValidations {
    struct TeamLeaderInfo {
        TeamLeaderNFT.TeamLeaderData teamLeader;
        uint256 maxMultiplier;
        bool inBlacklist;
    }

    Employees private employees;
    TeamLeaderNFT private teamLeader;

    constructor() {
        _setupRole(MAIN_OWNER, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function initialize(address _employees, address _teamLeader)
        external
        initializer
    {
        employees = Employees(_employees);
        teamLeader = TeamLeaderNFT(_teamLeader);
    }

    // Getters

    function getTeamLeaderInfo() external view returns (TeamLeaderInfo memory) {
        require(teamLeader.balanceOf(_msgSender()) == 1, "TL: Invalid owner");

        uint256 _teamLeaderID = teamLeader.tokenOfOwnerByIndex(_msgSender(), 0);

        return
            TeamLeaderInfo(
                teamLeader.getData(_teamLeaderID),
                getMaxMultiplicator(_msgSender()),
                isInBlackList(_teamLeaderID)
            );
    }

    function getMaxMultiplicator(address _owner)
        public
        view
        override
        returns (uint8)
    {
        if (teamLeader.balanceOf(_owner) == 1) {
            uint256 _teamLeaderID = teamLeader.tokenOfOwnerByIndex(_owner, 0);

            if (
                teamLeader.validate(_teamLeaderID) &&
                !isInBlackList(_teamLeaderID)
            ) {
                uint256 _balance = employees.balanceOf(_owner);

                for (uint256 i = 0; i < validMultiplicators.length; i++) {
                    if (_balance < validMultiplicators[i]) return uint8(i);
                }

                return 1;
            }
        }

        return 0;
    }

    function isInBlackList(uint256 _id) public view override returns (bool) {
        return blackList[_id];
    }

    //Update

    function mintLeader() external override {
        teamLeader.mint(_msgSender());
        emit MintLeader(_msgSender(), block.timestamp);
    }

    function addToBlacklist(uint256 _id, bool _state)
        external
        override
        onlyRole(MAIN_OWNER)
    {
        blackList[_id] = _state;
    }

    function updateRegisterAddress(address _employees, address _teamLeader)
        external
        override
        onlyRole(MAIN_OWNER)
    {
        employees = Employees(_employees);
        teamLeader = TeamLeaderNFT(_teamLeader);
    }

    function addXPToOwner(address _owner, uint256 _xp)
        external
        override
        onlyRole(LINK)
    {
        uint256 _teamLeaderID = teamLeader.tokenOfOwnerByIndex(_owner, 0);

        require(
            teamLeader.validate(_teamLeaderID) && !isInBlackList(_teamLeaderID),
            INVALID_LEADER
        );

        uint256 _nextXP = teamLeader.getNextLevelXP(_teamLeaderID);

        if (teamLeader.getXP(_teamLeaderID) + _xp >= _nextXP) {
            teamLeader.changeLevel(
                _teamLeaderID,
                teamLeader.getLevel(_teamLeaderID) + 1
            );

            teamLeader.changeNextLevelXP(_teamLeaderID, _nextXP * 2);
        }

        teamLeader.addXP(_teamLeaderID, _xp);

        emit IncreaseXP(_teamLeaderID, _xp, block.timestamp);
    }
}
