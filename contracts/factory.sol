// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./libraries/factory.sol";

contract Factories is Context, AccessControl, ERC721Enumerable {
    string private _baseUri = "";
    uint256 private _count = 1;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant CONNECTION = keccak256("CONNECTION");

    mapping(uint256 => FactoryLibrary.FactoryNFT) private factories;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURN_ROLE, _msgSender());
        _setupRole(CONNECTION, _msgSender());
        _baseUri = baseUri;
    }

    function uri() public view returns (string memory) {
        return _baseUri;
    }

    function getFactory(uint256 id)
        public
        view
        returns (FactoryLibrary.FactoryNFTData memory)
    {
        return FactoryLibrary.FactoryNFTData(factories[id], tokenURI(id));
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory union = string(
            abi.encodePacked(
                "build:",
                Strings.toString(factories[id].build),
                ";model:",
                Strings.toString(factories[id].model),
                ";points:",
                Strings.toString(factories[id].points)
            )
        );

        return
            string(
                abi.encodePacked(
                    _baseUri,
                    "?a=",
                    union,
                    ";id:",
                    Strings.toString(id)
                )
            );
    }

    function mint(
        uint8 build,
        uint8 model,
        uint256 points,
        address to
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Factories: Invalid minter"
        );

        factories[_count] = FactoryLibrary.FactoryNFT(build, model, points);

        _mint(to, _count);
        _count++;
    }

    function burn(uint256 id) public virtual {
        require(
            _exists(id) &&
                (ownerOf(id) == _msgSender() ||
                    hasRole(BURN_ROLE, _msgSender())),
            "Factories: Burn error"
        );

        delete factories[id];
        _burn(id);
    }

    // Getters

    function getMultiplier(uint256 id) public view virtual returns (uint256) {
        return factories[id].points;
    }

    function getType(uint256 id) public view virtual returns (uint8) {
        return factories[id].build;
    }

    function getModel(uint256 id) public view virtual returns (uint8) {
        return factories[id].model;
    }

    function addToMultiplier(uint256 id, uint256 points)
        public
        onlyRole(CONNECTION)
    {
        require(_exists(id), "Factories: Invalid factory.");
        factories[id].points += points;
    }

    function getCustomerFactories(address customer)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256[] memory nfts = new uint256[](balanceOf(customer));
        for (uint256 i = 0; i < nfts.length; i++) {
            nfts[i] = tokenOfOwnerByIndex(customer, i);
        }
        return nfts;
    }

    function validate(uint256 id) public view returns (bool) {
        return _exists(id) && factories[id].points != 0;
    }

    function isOwnerOfAll(address owner, uint256[] calldata ids)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            if (!validate(ids[i]) || (ownerOf(ids[i]) != owner)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
