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

contract VoltRewards is Context, Initializable, AccessControl {
    struct StakingData {
        uint256 lockedVolt;
        uint256 unlockedVolt;
        uint256 totalVolt;
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

    struct Reward {
        bool special;
        uint8 total;
        uint256 necesaryVolt;
    }

    event RequestMiniEmployees(MiniEmployeesRequest);

    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_VAULT = "CD: Invalid vault";
    string public constant INVALID_VAULTS = "CD: Invalid vaults";
    string public constant INVALID_TIME = "CD: Invalid request";
    string public constant INVALID_PARTICIPATION = "CD: Invalid participation";

    IERC721Enumerable private vaultNFT; // 0xc3a1cF832A77fcAe51cEa2E1B03EF85492F531Ac
    IERC20 private volt; // 0x8df95e66cb0ef38f91d2776da3c921768982fba0
    IGeyser private geyser; // 0xBfC69a757Dd7DB8C59e10c63aB023dc8c8cc95Dc
    MiniEmployees private miniEmployees;
    EBaseDeployer private baseDeployer;

    mapping(address => uint256) private requests;
    mapping(uint8 => Reward) private prototype;

    uint256 private resetTime;
    uint256 private minStakingTime = 86400;
    uint256 private requestTiming = 86400;

    function initialize(
        address _vaultNFT,
        address _volt,
        address _geyser,
        address _baseDeployer,
        address _miniEmployees
    ) public initializer {
        _setupRole(MAIN_OWNER, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        resetTime = block.timestamp;
        vaultNFT = IERC721Enumerable(_vaultNFT);
        volt = IERC20(_volt);
        geyser = IGeyser(_geyser);
        baseDeployer = EBaseDeployer(_baseDeployer);
        miniEmployees = MiniEmployees(_miniEmployees);

        prototype[3] = Reward(false, 1, 10000000000000000000000);
        prototype[2] = Reward(false, 2, 20000000000000000000000);
        prototype[1] = Reward(true, 1, 50000000000000000000000);
        prototype[0] = Reward(true, 2, 100000000000000000000000);
    }

    function updateTime() external onlyRole(MAIN_OWNER) {
        resetTime = block.timestamp;
    }

    function changePrototype(uint8 _id, bool _special, uint8 _amount, uint256 _necesaryVolt) external onlyRole(MAIN_OWNER) {
        prototype[_id] = Reward(_special, _amount, _necesaryVolt);
    }

    function changeMinStakingTime(uint256 _time) external onlyRole(MAIN_OWNER) {
        minStakingTime = _time;
    }

    function changeRequestTiming(uint256 _time) external onlyRole(MAIN_OWNER) {
        requestTiming = _time;
    }

    function changeDirections(
        address _vaultNFT,
        address _volt,
        address _geyser,
        address _baseDeployer,
        address _miniEmployees
    ) external onlyRole(MAIN_OWNER) {
        vaultNFT = IERC721Enumerable(_vaultNFT);
        volt = IERC20(_volt);
        geyser = IGeyser(_geyser);
        baseDeployer = EBaseDeployer(_baseDeployer);
        miniEmployees = MiniEmployees(_miniEmployees);
    }

    function getStakingData() public view returns (StakingData memory) {
        uint256 _lockedVolt = getLockedVolt(_msgSender());
        uint256 _unlockedVolt = getUnlockedVolt(_msgSender());

        return
            StakingData(
                _lockedVolt,
                _unlockedVolt,
                _lockedVolt + _unlockedVolt,
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
            requests[_owner] <= resetTime && getLockedVolt(_owner) >= prototype[3].necesaryVolt;
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

    function getLockedVolt(address _owner) public view returns (uint256) {
        uint256 _vaultsBalance = vaultNFT.balanceOf(_owner);
        uint256 _lockedVolt = 0;

        for (uint256 i = 0; i < _vaultsBalance; i++) {
            _lockedVolt += getVaultsBalance(
                address(uint160(vaultNFT.tokenOfOwnerByIndex(_owner, i)))
            );
        }

        return _lockedVolt;
    }

    function getUnlockedVolt(address _owner) public view returns (uint256) {
        return volt.balanceOf(_owner);
    }

    function getTotalVolt(address _owner) public view returns (uint256) {
        return getUnlockedVolt(_owner) + getLockedVolt(_owner);
    }

    function getVaultsBalance(address vault) public view returns (uint256) {
        return IUniversalVault(vault).getBalanceLocked(address(volt));
    }

    function getVaultBalanceByNFT(uint256 id) public view returns (uint256) {
        return getVaultsBalance(address(uint160(id)));
    }

    function getValidPrototype(address _owner) public view returns(uint8) {
        if(canRequestDailyMiniEmployees(_owner)) {
            uint8 _requestID = 3;

            for(uint8 i = 0 ; i < 4; i++) {
                if(validatePrototype(_owner, i)) {
                    _requestID = i;
                    break;
                }
            }

            return _requestID;
        }else return 100;
    }

    function validatePrototype(address _owner, uint8 _prototype) public view returns(bool) {
        return prototype[_prototype].necesaryVolt <= getLockedVolt(_owner);
    }

    function requestMiniEmployeesWithVolt() external {
        require(canRequestDailyMiniEmployees(_msgSender()), INVALID_TIME);

        uint8 _selectedPrototype = getValidPrototype(_msgSender());

        if(_selectedPrototype != 100) {
            uint8[] memory _randoms = baseDeployer.randomBuildTypes(
                4 * prototype[_selectedPrototype].total
            );

            if(prototype[_selectedPrototype].special) {
                for (uint8 i = 0; i < _randoms.length; i += 4) {
                    miniEmployees.mint(
                        _randoms[i],
                        _randoms[i + 1],
                        _randoms[i + 2],
                        _randoms[i],
                        1,
                        baseDeployer.calcEmployeePoints(
                            [
                                _randoms[i],
                                _randoms[i + 1],
                                _randoms[i + 2],
                                _randoms[i]
                            ]
                        ),
                        _msgSender()
                    );
                }
            }else {
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
            }
        
            requests[_msgSender()] = block.timestamp;

            emit RequestMiniEmployees(
                MiniEmployeesRequest(
                    _msgSender(),
                    prototype[_selectedPrototype].total,
                    getLockedVolt(_msgSender()),
                    block.timestamp
                )
            );
        }
    }
}
