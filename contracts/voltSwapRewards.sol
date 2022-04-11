// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./interfaces/EGeyser.sol";
import "./interfaces/EUniversalVault.sol";
import "./miniEmployee.sol";
import "./interfaces/EBaseDeployer.sol";

contract VoltSwapRewards is Context, Initializable, AccessControl {
    struct StakingData {
        uint256 lockedLPs;
        uint256 unlockedLPs;
        uint256 totalLPs;
        uint256 LPsSupply;
        uint256 LPsPercentage;
        bool hasValidVault;
        bool canRequestMiniEmployees;
    }

    struct VaultWithTime {
        address vault;
        uint256 timestamp;
    }

    struct MiniEmployeesRequest {
        address owner;
        uint8 totalNFTs;
        uint256 participation;
        uint256 timestamp;
    }

    event RequestMiniEmployees(MiniEmployeesRequest);

    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_VAULT = "CD: Invalid vault";
    string public constant INVALID_VAULTS = "CD: Invalid vaults";
    string public constant INVALID_TIME = "CD: Invalid request";
    string public constant INVALID_PARTICIPATION = "CD: Invalid participation";

    IERC721Enumerable private vaultNFT; // 0xc3a1cF832A77fcAe51cEa2E1B03EF85492F531Ac
    IERC20 private lp; // 0x931bb8c7fb6cD099678faE36a5370577cEE18ADe
    IGeyser private geyser; // 0x5fa46Be49ba496c7e9632C65075eacED062a30f0
    MiniEmployees private miniEmployees;
    EBaseDeployer private baseDeployer;
    // Vault example 0xBfC69a757Dd7DB8C59e10c63aB023dc8c8cc95Dc

    mapping(address => uint256) private requests;

    uint8 private minLPPercetage = 1;
    uint8 private miniEmployeesPerRequest = 5;

    uint256 private resetTime;
    uint256 private minStakingTime = 86400;
    uint256 private requestTiming = 86400;

    function initialize(
        address _vaultNFT,
        address _lp,
        address _geyser,
        address _baseDeployer,
        address _miniEmployees
    ) public initializer {
        _setupRole(MAIN_OWNER, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        resetTime = block.timestamp;
        vaultNFT = IERC721Enumerable(_vaultNFT);
        lp = IERC20(_lp);
        geyser = IGeyser(_geyser);
        baseDeployer = EBaseDeployer(_baseDeployer);
        miniEmployees = MiniEmployees(_miniEmployees);
    }

    function updateTime() external onlyRole(MAIN_OWNER) {
        resetTime = block.timestamp;
    }

    function changeMinStakingTime(uint256 _time) external onlyRole(MAIN_OWNER) {
        minStakingTime = _time;
    }

    function changeRequestTiming(uint256 _time) external onlyRole(MAIN_OWNER) {
        requestTiming = _time;
    }

    function changeDirections(
        address _vaultNFT,
        address _lp,
        address _geyser,
        address _baseDeployer,
        address _miniEmployees
    ) external onlyRole(MAIN_OWNER) {
        vaultNFT = IERC721Enumerable(_vaultNFT);
        lp = IERC20(_lp);
        geyser = IGeyser(_geyser);
        baseDeployer = EBaseDeployer(_baseDeployer);
        miniEmployees = MiniEmployees(_miniEmployees);
    }

    function changeLPPercentage(uint8 _percentage)
        external
        onlyRole(MAIN_OWNER)
    {
        minLPPercetage = _percentage;
    }

    function changeMiniEmployeesPerRequest(uint8 _number)
        external
        onlyRole(MAIN_OWNER)
    {
        miniEmployeesPerRequest = _number;
    }

    function getStakingData() public view returns (StakingData memory) {
        uint256 _lockedLPs = getLockedLPs(_msgSender());
        uint256 _unlockedLPs = getUnlockedLPs(_msgSender());
        uint256 _totalSupply = lp.totalSupply();

        return
            StakingData(
                _lockedLPs,
                _unlockedLPs,
                _lockedLPs + _unlockedLPs,
                _totalSupply,
                getLPParticipation(_msgSender()),
                hasAValidVault(_msgSender()),
                canRequestDailyMiniEmployees(_msgSender())
            );
    }

    function canRequestDailyMiniEmployees(address _owner)
        public
        view
        returns (bool)
    {
        return
            hasAValidVault(_owner) &&
            requests[_owner] <= resetTime &&
            getLPParticipation(_owner) >= minLPPercetage;
    }

    function getCustomerVaults(address _owner)
        public
        view
        returns (address[] memory)
    {
        uint256 _vaultsBalance = vaultNFT.balanceOf(_owner);
        address[] memory _vaults = new address[](_vaultsBalance);

        for (uint256 i = 0; i < _vaultsBalance; i++) {
            _vaults[i] = address(
                uint160(vaultNFT.tokenOfOwnerByIndex(_owner, i))
            );
        }

        return _vaults;
    }

    function hasAValidVault(address _owner) public view returns (bool) {
        bool _validVault = false;

        VaultWithTime[] memory _vaults = getPosibleValidVaultsTimes(_owner);

        for (uint256 i = 0; i < _vaults.length; i++) {
            if (_vaults[i].timestamp + minStakingTime <= block.timestamp) {
                _validVault = true;
                break;
            }
        }

        return _validVault;
    }

    function getPosibleValidVaultsTimes(address _owner)
        public
        view
        returns (VaultWithTime[] memory)
    {
        uint256 _vaultsBalance = vaultNFT.balanceOf(_owner);
        VaultWithTime[] memory _times = new VaultWithTime[](_vaultsBalance);

        for (uint256 i = 0; i < _vaultsBalance; i++) {
            address _vault = address(
                uint160(vaultNFT.tokenOfOwnerByIndex(_owner, i))
            );

            _times[i] = VaultWithTime(
                _vault,
                geyser.getVaultData(_vault).stakes[0].timestamp
            );
        }

        return _times;
    }

    function getLockedLPs(address _owner) public view returns (uint256) {
        uint256 _vaultsBalance = vaultNFT.balanceOf(_owner);
        uint256 _lockedLPs = 0;

        for (uint256 i = 0; i < _vaultsBalance; i++) {
            _lockedLPs += getVaultsBalance(
                address(uint160(vaultNFT.tokenOfOwnerByIndex(_owner, i)))
            );
        }

        return _lockedLPs;
    }

    function getUnlockedLPs(address _owner) public view returns (uint256) {
        return lp.balanceOf(_owner);
    }

    function getTotalLPs(address _owner) public view returns (uint256) {
        return getUnlockedLPs(_owner) + getLockedLPs(_owner);
    }

    function getVaultsBalance(address vault) public view returns (uint256) {
        return IUniversalVault(vault).getBalanceLocked(address(lp));
    }

    function getVaultBalanceByNFT(uint256 id) public view returns (uint256) {
        return getVaultsBalance(address(uint160(id)));
    }

    function getLPParticipation(address _owner) public view returns (uint256) {
        return (getTotalLPs(_owner) * 100) / lp.totalSupply();
    }

    function requestMiniEmployeesWithLP() external {
        require(canRequestDailyMiniEmployees(_msgSender()), INVALID_TIME);

        uint8[] memory _randoms = baseDeployer.randomBuildTypes(
            4 * miniEmployeesPerRequest
        );

        for (uint8 i = 0; i < _randoms.length; i += 4) {
            miniEmployees.mint(
                _randoms[i],
                _randoms[i + 1],
                _randoms[i + 2],
                _randoms[i + 3],
                0,
                baseDeployer.calcEmployeePoints(
                    [
                        _randoms[i],
                        _randoms[i + 1],
                        _randoms[i + 2],
                        _randoms[i + 3]
                    ]
                ),
                _msgSender()
            );
        }

        requests[_msgSender()] = block.timestamp;

        emit RequestMiniEmployees(
            MiniEmployeesRequest(
                _msgSender(),
                miniEmployeesPerRequest,
                getLPParticipation(_msgSender()),
                block.timestamp
            )
        );
    }
}
