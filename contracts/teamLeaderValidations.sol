// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ETeamLeaderValidations.sol";
import "./employee.sol";
import "./miniEmployee.sol";
import "./factory.sol";
import "./multiEmployee.sol";

contract TeamLeaderValidations is ETeamLeaderValidations {
    Employees private employees;
    MiniEmployees private miniEmployees;
    MultiEmployees private multiEmployees;
    Factories private factories;
    TeamLeaderNFT private teamLeader;

    constructor() {
        _setupRole(MAIN_OWNER, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function initialize(
        address _employees,
        address _miniEmployees,
        address _factories,
        address _multiEmployees,
        address _teamLeader
    ) external initializer {
        employees = Employees(_employees);
        miniEmployees = MiniEmployees(_miniEmployees);
        factories = Factories(_factories);
        multiEmployees = MultiEmployees(_multiEmployees);
        teamLeader = TeamLeaderNFT(_teamLeader);
    }

    function updateAddresses(
        address _employees,
        address _miniEmployees,
        address _factories,
        address _multiEmployees,
        address _teamLeader
    ) external override onlyRole(MAIN_OWNER) {
        employees = Employees(_employees);
        miniEmployees = MiniEmployees(_miniEmployees);
        factories = Factories(_factories);
        multiEmployees = MultiEmployees(_multiEmployees);
        teamLeader = TeamLeaderNFT(_teamLeader);
    }

    // Getters

    function getReward(uint256 _id)
        external
        view
        override
        returns (XPReward memory)
    {
        return rewards[_id];
    }

    function getRewardInfo(uint256 _id, address _owner)
        external
        view
        override
        returns (XPRewardsInfo memory)
    {
        return XPRewardsInfo(rewards[_id], canRequestRewards(_id, _owner));
    }

    function canRequestRewards(uint256 _id, address _owner)
        public
        view
        override
        returns (bool)
    {
        return
            !rewardsRequests[_owner][_id] &&
            rewards[_id].level <=
            teamLeader.getLevel(teamLeader.tokenOfOwnerByIndex(_owner, 0));
    }

    function getRewards() external view override returns (XPReward[] memory) {
        XPReward[] memory _rewardsInfo = new XPReward[](totalRewards);

        for (uint256 i = 0; i < totalRewards; i++) {
            _rewardsInfo[i] = rewards[i];
        }

        return _rewardsInfo;
    }

    function getRewardsInfo(address _owner)
        external
        view
        override
        returns (XPRewardsInfo[] memory)
    {
        XPRewardsInfo[] memory _rewardsInfo = new XPRewardsInfo[](totalRewards);

        for (uint256 i = 0; i < totalRewards; i++) {
            _rewardsInfo[i] = XPRewardsInfo(
                rewards[i],
                canRequestRewards(i, _owner)
            );
        }

        return _rewardsInfo;
    }

    function updateReward(
        uint256 _id,
        EmployeeLibrary.EmployeeNFT calldata _employee,
        EmployeeLibrary.EmployeeChildrenNFT calldata _miniEmployee,
        FactoryLibrary.FactoryNFT calldata _factory,
        EmployeeLibrary.EmployeeNFT calldata _multiEmployee,
        uint256 _level
    ) external override onlyRole(MAIN_OWNER) {
        rewards[_id] = XPReward(
            _employee,
            _miniEmployee,
            _factory,
            _multiEmployee,
            _level
        );
    }

    function updateRewardRequest(
        address _owner,
        uint256 _id,
        bool _state
    ) external override onlyRole(MAIN_OWNER) {
        rewardsRequests[_owner][_id] = _state;
    }

    function requestRewards(uint256 _id) external override {
        require(
            !isInBlackList(teamLeader.tokenOfOwnerByIndex(_msgSender(), 0)),
            BLACK_LISTED
        );

        require(canRequestRewards(_id, _msgSender()), INVALID_REWARDS);

        if (rewards[_id].employee.points > 0) {
            employees.mint(
                rewards[_id].employee.head,
                rewards[_id].employee.body,
                rewards[_id].employee.legs,
                rewards[_id].employee.hands,
                rewards[_id].employee.points,
                _msgSender()
            );
        }

        if (rewards[_id].miniEmployee.points > 0) {
            miniEmployees.mint(
                rewards[_id].miniEmployee.head,
                rewards[_id].miniEmployee.body,
                rewards[_id].miniEmployee.legs,
                rewards[_id].miniEmployee.hands,
                rewards[_id].miniEmployee.net,
                rewards[_id].miniEmployee.points,
                _msgSender()
            );
        }

        if (rewards[_id].multiEmployee.points > 0) {
            multiEmployees.mint(
                rewards[_id].multiEmployee.head,
                rewards[_id].multiEmployee.body,
                rewards[_id].multiEmployee.legs,
                rewards[_id].multiEmployee.hands,
                rewards[_id].multiEmployee.points,
                _msgSender()
            );
        }

        if (rewards[_id].factory.points > 0) {
            factories.mint(
                rewards[_id].factory.build,
                rewards[_id].factory.model,
                rewards[_id].factory.points,
                _msgSender()
            );
        }

        rewardsRequests[_msgSender()][_id] = true;
    }

    function updateTotalRewards(uint256 _total)
        external
        override
        onlyRole(MAIN_OWNER)
    {
        totalRewards = _total;
    }

    function getTeamLeaderInfo()
        external
        view
        override
        returns (TeamLeaderInfo memory)
    {
        require(teamLeader.balanceOf(_msgSender()) == 1, INVALID_OWNER);

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

                if (_balance >= 104) return 40;
                else {
                    for (uint256 i = 0; i < validMultiplicators.length; i++) {
                        if (_balance < validMultiplicators[i]) return uint8(i);
                    }

                    return 1;
                }
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
        uint256 _totalXP = teamLeader.getXP(_teamLeaderID) + _xp;
        uint256 _level = teamLeader.getLevel(_teamLeaderID);
        uint256 _nextLevelXP = _nextXP * 2;

        if (_totalXP >= _nextXP) {
            _level++;

            teamLeader.changeLevel(_teamLeaderID, _level);

            teamLeader.changeNextLevelXP(_teamLeaderID, _nextLevelXP);
        }

        teamLeader.addXP(_teamLeaderID, _xp);

        emit IncreaseXP(
            Incrementation(
                _teamLeaderID,
                _totalXP,
                _level,
                _nextLevelXP,
                block.timestamp
            )
        );
    }
}
