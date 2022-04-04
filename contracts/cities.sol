// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./libraries/cities.sol";

contract Cities is Context, AccessControl, ERC721Enumerable {
    string private _baseUri = "";
    uint256 private _count = 1;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");

    string public constant INVALID_P_PER_LAND = "C: Invalid points per land";
    string public constant INVALID_MINTER = "C: Invalid minter";
    string public constant BURN_ERROR = "C: Burn error";
    string public constant INVALID_ID = "C: NFT error";
    string public constant INVALID_OWNER = "C: Invalid owner";

    mapping(uint256 => CitiesLibrary.City) private cities;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURN_ROLE, _msgSender());
        _baseUri = baseUri;
    }

    function uri() public view virtual returns (string memory) {
        return _baseUri;
    }

    function getData(uint256 id)
        public
        view
        virtual
        returns (CitiesLibrary.CityData memory)
    {
        return CitiesLibrary.CityData(cities[id], tokenURI(id));
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory union = string(
            abi.encodePacked(
                "p:",
                Strings.toString(cities[id].factoryPoints),
                ";l:",
                Strings.toString(cities[id].lands),
                ";w:",
                Strings.toString(cities[id].world),
                ";t:",
                Strings.toString(cities[id].townHall),
                ";u:",
                Strings.toString(cities[id].university)
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
        uint256 factoryPoints,
        uint256 world,
        string calldata name,
        uint16 pointsPerLand,
        address to
    ) public virtual onlyRole(MINTER_ROLE) {
        require(pointsPerLand != 0, INVALID_P_PER_LAND);

        cities[_count] = CitiesLibrary.City(
            factoryPoints,
            factoryPoints / pointsPerLand,
            world,
            0,
            0,
            name
        );

        _mint(to, _count);
        _count++;
    }

    function burn(uint256 id) public virtual {
        require(
            _exists(id) &&
                ((ownerOf(id) == _msgSender()) ||
                    hasRole(BURN_ROLE, _msgSender())),
            BURN_ERROR
        );

        delete cities[id];
        _burn(id);
    }

    function addPoints(
        uint256 id,
        uint256 points,
        uint16 pointsPerLand
    ) public onlyRole(MINTER_ROLE) {
        require(_exists(id), INVALID_ID);
        require(pointsPerLand != 0, INVALID_P_PER_LAND);
        cities[id].factoryPoints += points;
        cities[id].lands = cities[id].factoryPoints / pointsPerLand;
    }

    function changePoints(
        uint256 id,
        uint256 points,
        uint16 pointsPerLand
    ) public onlyRole(MINTER_ROLE) {
        require(_exists(id), INVALID_ID);
        cities[id].factoryPoints = points;
        cities[id].lands = cities[id].factoryPoints / pointsPerLand;
    }

    function changeName(uint256 id, string calldata name) public {
        require(_exists(id), INVALID_ID);
        require(ownerOf(id) == msg.sender, INVALID_OWNER);
        cities[id].name = name;
    }

    function changeUniversityState(uint256 id, uint256 _uinversity)
        public
        onlyRole(MINTER_ROLE)
    {
        require(_exists(id), INVALID_ID);
        cities[id].university = _uinversity;
    }

    function changeTownHallState(uint256 id, uint256 _townHall)
        public
        onlyRole(MINTER_ROLE)
    {
        require(_exists(id), INVALID_ID);
        cities[id].townHall = _townHall;
    }

    function changeWorld(uint256 id, uint256 world)
        public
        onlyRole(MINTER_ROLE)
    {
        require(_exists(id), INVALID_ID);
        cities[id].world = world;
    }

    //Getters

    function getLands(uint256 id) public view virtual returns (uint256) {
        return cities[id].lands;
    }

    function getPoints(uint256 id) public view virtual returns (uint256) {
        return cities[id].factoryPoints;
    }

    function getWorld(uint256 id) public view virtual returns (uint256) {
        return cities[id].world;
    }

    function hasUniversity(uint256 id) public view virtual returns (bool) {
        return cities[id].university != 0;
    }

    function hasTownHall(uint256 id) public view virtual returns (bool) {
        return cities[id].townHall != 0;
    }

    function getTownHall(uint256 id) public view virtual returns (uint256) {
        return cities[id].townHall;
    }

    function getUniversity(uint256 id) public view virtual returns (uint256) {
        return cities[id].university;
    }

    function validate(uint256 id) public view returns (bool) {
        return _exists(id) && cities[id].factoryPoints != 0;
    }

    function getCustomerCities(address customer)
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
