// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract TeamLeaderNFT is Context, AccessControl, ERC721Enumerable {
    struct TeamLeader {
        uint256 xp;
        uint256 level;
        uint256 nextLevelXP;
        uint256 startTime;
    }

    struct TeamLeaderData {
        TeamLeader leader;
        string uri;
    }

    bool private _lockTransfers = true;

    uint256 private _count = 1;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");

    string private _baseUri = "";

    mapping(uint256 => TeamLeader) private leaders;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BURN_ROLE, _msgSender());
        _baseUri = baseUri;
    }

    function changeBaseUri(string memory _uri)
        external
        virtual
        onlyRole(MINTER_ROLE)
    {
        _baseUri = _uri;
    }

    function uri() external view virtual returns (string memory) {
        return _baseUri;
    }

    function toggleTransfers() external onlyRole(MINTER_ROLE) {
        _lockTransfers = !_lockTransfers;
    }

    function getData(uint256 id)
        external
        view
        virtual
        returns (TeamLeaderData memory)
    {
        return TeamLeaderData(leaders[id], tokenURI(id));
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory union = string(
            abi.encodePacked(
                "xp:",
                Strings.toString(leaders[id].xp),
                ";level:",
                Strings.toString(leaders[id].level),
                ";time:",
                Strings.toString(leaders[id].startTime)
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

    function mint(address _to) external virtual onlyRole(MINTER_ROLE) {
        leaders[_count] = TeamLeader(0, 0, 10, block.timestamp);
        _mint(_to, _count);
        _count++;
    }

    function burn(uint256 id) external virtual {
        require(
            _exists(id) &&
                ((ownerOf(id) == _msgSender()) ||
                    hasRole(BURN_ROLE, _msgSender())),
            "Employees: Burn error."
        );

        delete leaders[id];
        _burn(id);
    }

    //Getters

    function getXP(uint256 id) external view virtual returns (uint256) {
        return leaders[id].xp;
    }

    function getStartTime(uint256 id) external view virtual returns (uint256) {
        return leaders[id].startTime;
    }

    function getNextLevelXP(uint256 _id)
        external
        view
        virtual
        returns (uint256)
    {
        return leaders[_id].nextLevelXP;
    }

    function getLevel(uint256 _id) external view returns (uint256) {
        return leaders[_id].level;
    }

    function addXP(uint256 _id, uint256 _xp)
        external
        virtual
        onlyRole(MINTER_ROLE)
    {
        require(_exists(_id), "TL: Invalid NFT.");
        leaders[_id].xp += _xp;
    }

    function removeXP(uint256 _id, uint256 _xp)
        external
        virtual
        onlyRole(MINTER_ROLE)
    {
        require(_exists(_id), "TL: Invalid NFT.");
        leaders[_id].xp -= _xp;
    }

    function changeLevel(uint256 _id, uint256 _level)
        external
        onlyRole(MINTER_ROLE)
    {
        leaders[_id].level = _level;
    }

    function changeNextLevelXP(uint256 _id, uint256 _nextLevelXP)
        external
        onlyRole(MINTER_ROLE)
    {
        leaders[_id].nextLevelXP = _nextLevelXP;
    }

    function validate(uint256 id) public view returns (bool) {
        return _exists(id) && leaders[id].startTime != 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            from == address(0) || !_lockTransfers,
            "TL: You can't transfer this NFT."
        );

        require(balanceOf(to) == 0, "TL: Invalid destiny");

        super._beforeTokenTransfer(from, to, tokenId);
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
