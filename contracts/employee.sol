// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./libraries/employee.sol";

contract Employees is Context, AccessControl, ERC721Enumerable {
    string private _baseUri = "";
    uint256 private _count = 1;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");

    mapping(uint256 => EmployeeLibrary.EmployeeNFT) private employees;

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

    function getEmployee(uint256 id)
        public
        view
        virtual
        returns (EmployeeLibrary.EmployeeNFTData memory)
    {
        return EmployeeLibrary.EmployeeNFTData(employees[id], tokenURI(id));
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory union = string(
            abi.encodePacked(
                "head:",
                Strings.toString(employees[id].head),
                ";body:",
                Strings.toString(employees[id].body),
                ";legs:",
                Strings.toString(employees[id].legs),
                ";hands:",
                Strings.toString(employees[id].hands),
                ";points:",
                Strings.toString(employees[id].points)
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
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Employees: Invalid minter"
        );

        employees[_count] = EmployeeLibrary.EmployeeNFT(
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
            _exists(id) &&
                ((ownerOf(id) == _msgSender()) ||
                    hasRole(BURN_ROLE, _msgSender())),
            "Employees: Burn error."
        );

        delete employees[id];
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
            employees[id].head,
            employees[id].body,
            employees[id].legs,
            employees[id].hands
        ];
    }

    function getType(uint256 id) public view virtual returns (uint8) {
        return employees[id].head;
    }

    function getPoints(uint256 id) public view virtual returns (uint16) {
        return employees[id].points;
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
        return _exists(id) && employees[id].points != 0;
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
