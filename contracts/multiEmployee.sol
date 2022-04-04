// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./libraries/employee.sol";

contract MultiEmployees is Context, AccessControl, ERC721Enumerable {
    string private _baseUri = "";
    uint256 private _count = 1;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public constant MAX_SUPPLY_LIMIT = "ME: Max supply limit";
    string public constant INVALID_CUSTOMER_BALANCE = "ME: Invalid balance";

    mapping(uint256 => EmployeeLibrary.EmployeeNFT) private multiEmployees;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _baseUri = baseUri;
    }

    function uri() public view virtual returns (string memory) {
        return _baseUri;
    }

    function getEmployee(uint256 id)
        public
        view
        virtual
        returns (EmployeeLibrary.EmployeeNFTData memory)
    {
        return
            EmployeeLibrary.EmployeeNFTData(multiEmployees[id], tokenURI(id));
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory union = string(
            abi.encodePacked(
                "head:",
                Strings.toString(multiEmployees[id].head),
                ";body:",
                Strings.toString(multiEmployees[id].body),
                ";legs:",
                Strings.toString(multiEmployees[id].legs),
                ";hands:",
                Strings.toString(multiEmployees[id].hands),
                ";points:",
                Strings.toString(multiEmployees[id].points)
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
        uint8 head,
        uint8 body,
        uint8 legs,
        uint8 hands,
        uint16 points,
        address to
    ) public virtual onlyRole(MINTER_ROLE) {
        multiEmployees[_count] = EmployeeLibrary.EmployeeNFT(
            head,
            body,
            legs,
            hands,
            points
        );

        _mint(to, _count);
        _count++;
    }

    function burn(uint256 id) public virtual {
        require(
            _exists(id) && ((ownerOf(id) == _msgSender())),
            "Employees: Burn error."
        );

        delete multiEmployees[id];
        _burn(id);
    }

    //Getters

    function getParts(uint256 id)
        public
        view
        virtual
        returns (uint8[4] memory)
    {
        return [
            multiEmployees[id].head,
            multiEmployees[id].body,
            multiEmployees[id].legs,
            multiEmployees[id].hands
        ];
    }

    function getType(uint256 id) public view virtual returns (uint8) {
        return multiEmployees[id].head;
    }

    function getPoints(uint256 id) public view virtual returns (uint16) {
        return multiEmployees[id].points;
    }

    function getCustomerEmployees(address customer)
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
        return _exists(id) && multiEmployees[id].points != 0;
    }

    function alterEmployeeType(
        uint256 id,
        uint8 build,
        uint16 points
    ) public onlyRole(MINTER_ROLE) {
        multiEmployees[id].head = build;
        multiEmployees[id].body = build;
        multiEmployees[id].legs = build;
        multiEmployees[id].hands = build;
        multiEmployees[id].points = points;
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
