// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./libraries/BBERC721.sol";
import "./libraries/nftBridge.sol";

contract NFTBridgeStorage is Context, AccessControl {
    event LimboRequest(NFTBridgeLibrary.LimboRequest);
    event ReleaseFromLimbo(NFTBridgeLibrary.ReleaseFromLimbo);
    event UpdateConfiguration(bool, uint8, uint256);
    event SaveMinted(NFTBridgeLibrary.SavedMinted);

    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    string public constant INVALID_REQUEST = "TC: Invalid request";
    string public constant INVALID_STATUS = "TC: Invalid status";
    string public constant INVALID_NFT_QUANTITY = "TC: Invalid quantity";
    string public constant INVALID_FEE = "TC: Invalid fee";
    string public constant INVALID_VALIDATOR = "TC: Invalid validator";
    string public constant INVALID_INITIAL_NET = "TC: Invalid initial network";
    string public constant INVALID_DESTINY_NET = "TC: Invalid destiny network";
    string public constant INVALID_CONTRACT = "TC: Invalid contract";
    string public constant INVALID_NFT_OWNER = "TC: Invalid owner";
    string public constant INVALID_LIMBO_NFT = "TC: Invalid limbo nft";
    string public constant LOCKED_ADDRESS = "TC: Locked address, wait please.";

    bool public open = false;
    uint8 public maxNFTs = 10;

    address public creator;

    uint256 public feePerNFT = 70000000000000000 wei;
    uint256 public counter = 1;
    uint256 public unreleasedCounter = 1;

    mapping(address => bool) private contracts; // contract => validation
    mapping(address => mapping(address => uint256[])) private limboNFTs; //Contract => owner => nfts
    mapping(address => mapping(uint256 => address)) private limbo; //Contract => nft => owner
    mapping(address => mapping(uint256 => bool)) private locked; // Contract => nft => locked
    mapping(address => mapping(uint256 => address)) private minted; // Contract => nft => owner

    modifier isOpen() {
        require(open, INVALID_STATUS);
        _;
    }

    constructor() {
        _setupRole(ROLE_ADMIN, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        creator = _msgSender();
    }

    function updateConfiguration(
        bool _open,
        uint8 _maxNFTs,
        uint256 _feePerNFT
    ) public onlyRole(ROLE_ADMIN) {
        open = _open;
        maxNFTs = _maxNFTs;
        feePerNFT = _feePerNFT;

        emit UpdateConfiguration(open, maxNFTs, feePerNFT);
    }

    function changeContractState(address _nft, bool _valid)
        public
        onlyRole(ROLE_ADMIN)
    {
        contracts[_nft] = _valid;
    }

    function isValidContract(address _contract) public view returns (bool) {
        return contracts[_contract];
    }

    function getBridgeData()
        public
        view
        returns (NFTBridgeLibrary.StorageData memory)
    {
        return NFTBridgeLibrary.StorageData(open, maxNFTs, feePerNFT);
    }

    function inLimbo(
        address _contract,
        address _owner,
        uint256 _id
    ) public view returns (bool) {
        return limbo[_contract][_id] == _owner;
    }

    function isLocked(address _contract, uint256 _nft)
        public
        view
        returns (bool)
    {
        return locked[_contract][_nft];
    }

    function getOriginalOwner(address _contract, uint256 _id)
        public
        view
        returns (address)
    {
        return limbo[_contract][_id];
    }

    function isOwnerOfAll(
        address _contract,
        address _owner,
        uint256[] memory _ids
    ) public view returns (bool) {
        bool isValid = true;

        for (uint256 i = 0; i < _ids.length; i++) {
            if (
                limbo[_contract][_ids[i]] != _owner ||
                locked[_contract][_ids[i]]
            ) {
                isValid = false;
            }
        }

        return isValid;
    }

    function allAreInLimbo(
        address _contract,
        address _owner,
        uint256[] memory _ids
    ) public view returns (bool) {
        bool allAreInTheLimbo = true;
        for (uint256 i = 0; i < _ids.length; i++) {
            if (
                limbo[_contract][_ids[i]] != _owner ||
                BBERC721(_contract).ownerOf(_ids[i]) != address(this)
            ) {
                return false;
            }
        }
        return allAreInTheLimbo;
    }

    function getLimboNFTs(address _contract, address _owner)
        public
        view
        returns (uint256[] memory)
    {
        return limboNFTs[_contract][_owner];
    }

    function lockMany(address _contract, uint256[] memory _nfts)
        public
        onlyRole(ROLE_ADMIN)
    {
        require(isValidContract(_contract), INVALID_CONTRACT);

        for (uint256 i = 0; i < _nfts.length; i++) {
            locked[_contract][_nfts[i]] = true;
        }
    }

    function unlockMany(address _contract, uint256[] memory _nfts)
        public
        onlyRole(ROLE_ADMIN)
    {
        require(isValidContract(_contract), INVALID_CONTRACT);

        for (uint256 i = 0; i < _nfts.length; i++) {
            locked[_contract][_nfts[i]] = false;
        }
    }

    function createLimboRequestWithMany(
        address _contract,
        uint256[] memory _ids
    ) public payable isOpen {
        require(isValidContract(_contract), INVALID_CONTRACT);
        require(_ids.length <= maxNFTs, INVALID_NFT_QUANTITY);
        require(msg.value == feePerNFT * _ids.length, INVALID_FEE);

        for (uint256 i = 0; i < _ids.length; i++) {
            BBERC721(_contract).transferFrom(
                _msgSender(),
                address(this),
                _ids[i]
            );

            limboNFTs[_contract][_msgSender()].push(_ids[i]);
            limbo[_contract][_ids[i]] = _msgSender();

            counter++;
        }

        emit LimboRequest(
            NFTBridgeLibrary.LimboRequest(
                _contract,
                _msgSender(),
                counter,
                _ids
            )
        );
    }

    function releaseManyFromLimbo(
        address _contract,
        address _owner,
        uint256[] memory _ids
    ) public onlyRole(ROLE_ADMIN) isOpen {
        require(isValidContract(_contract), INVALID_CONTRACT);
        require(_ids.length <= maxNFTs, INVALID_NFT_QUANTITY);

        for (uint256 i = 0; i < _ids.length; i++) {
            require(limbo[_contract][_ids[i]] == _owner, INVALID_LIMBO_NFT);

            limbo[_contract][_ids[i]] = address(0);
            BBERC721(_contract).burn(_ids[i]);
            releaseNFTFromLimbo(_contract, _owner, _ids[i]);

            unreleasedCounter++;
        }

        emit ReleaseFromLimbo(
            NFTBridgeLibrary.ReleaseFromLimbo(_contract, _msgSender(), _ids)
        );
    }

    function manyMinted(
        address _contract,
        address _owner,
        uint256[] memory _nfts
    ) public onlyRole(ROLE_ADMIN) {
        require(isValidContract(_contract), INVALID_CONTRACT);

        for (uint256 i = 0; i < _nfts.length; i++) {
            require(
                BBERC721(_contract).ownerOf(_nfts[i]) == address(this),
                INVALID_NFT_OWNER
            );

            minted[_contract][_nfts[i]] = _owner;
        }

        emit SaveMinted(NFTBridgeLibrary.SavedMinted(_contract, _owner, _nfts));
    }

    function expropiateMany(
        address _contract,
        address _owner,
        uint256[] memory _nfts
    ) public onlyRole(ROLE_ADMIN) {
        for (uint256 i = 0; i < _nfts.length; i++) {
            require(
                BBERC721(_contract).ownerOf(_nfts[i]) == address(this),
                INVALID_NFT_OWNER
            );

            BBERC721(_contract).transferFrom(
                address(this),
                minted[_contract][_nfts[i]],
                _nfts[i]
            );

            minted[_contract][_nfts[i]] = address(0);
        }

        emit SaveMinted(NFTBridgeLibrary.SavedMinted(_contract, _owner, _nfts));
    }

    function releaseNFTFromLimbo(
        address _contract,
        address _owner,
        uint256 _id
    ) private {
        for (uint256 j = 0; j < limboNFTs[_contract][_owner].length; j++) {
            if (limboNFTs[_contract][_owner][j] == _id) {
                limboNFTs[_contract][_owner][j] = limboNFTs[_contract][_owner][
                    limboNFTs[_contract][_owner].length - 1
                ];

                limboNFTs[_contract][_owner].pop();
                break;
            }
        }
    }

    function withdrawFees() public onlyRole(ROLE_ADMIN) {
        payable(_msgSender()).transfer(address(this).balance);
    }
}
