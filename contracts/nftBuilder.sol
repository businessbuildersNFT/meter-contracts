// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./libraries/nftBuilder.sol";

contract NFTBuilder is Context, Initializable, AccessControl {
    event AddNewRequest(Builder.Request);
    event ChangeRequestState(Builder.Request);

    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    uint8 public constant CREATOR_FEE = 50;
    uint8 public constant LIQUIDITY_FEE = 50;
    bool public open;

    string public constant INVALID_ADDRESS = "TC: Invalid Address";
    string public constant INVALID_TOKENS = "TC: Invalid Amount of tokens";
    string public constant INVALID_PAYMENT = "TC: Invalid payment";

    address[] customers;
    mapping(address => bool) requestCustomers;
    mapping(address => uint256[]) requestsByAddress;
    mapping(address => mapping(uint256 => Builder.Request)) private requests;

    uint256 public buildPrice = 50000000000000000000000 wei;

    address public creator;
    address public tokenReceiver;

    ERC20 private token;

    function initialize(ERC20 _token, address _tokenReceiver)
        public
        initializer
    {
        _setupRole(ROLE_ADMIN, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        token = _token;
        creator = _msgSender();
        tokenReceiver = _tokenReceiver;
    }

    function getData() public view returns (Builder.Data memory) {
        return
            Builder.Data(
                tokenReceiver,
                creator,
                buildPrice,
                CREATOR_FEE,
                LIQUIDITY_FEE
            );
    }

    function getCustomerRequests(address owner)
        public
        view
        returns (Builder.Request[] memory)
    {
        uint256 customerBalance = requestsByAddress[owner].length;

        Builder.Request[] memory customer = new Builder.Request[](
            customerBalance
        );

        for (uint256 i = 0; i < customerBalance; i++) {
            customer[i] = requests[owner][requestsByAddress[owner][i]];
        }

        return customer;
    }

    function getUnAcceptedRequests()
        public
        view
        returns (Builder.Request[] memory)
    {
        Builder.Request[] memory allRequests;
        uint256 counter = 0;

        for (uint256 i = 0; i < customers.length; i++) {
            uint256 customerBalance = requestsByAddress[customers[i]].length;
            if (customerBalance > 0) {
                for (uint256 j = 0; j < customerBalance; j++) {
                    Builder.Request memory request = requests[customers[i]][
                        requestsByAddress[customers[i]][j]
                    ];

                    if (request.isValid && !request.accepted) {
                        allRequests[counter] = request;
                        counter++;
                    }
                }
            }
        }

        return allRequests;
    }

    function getAcceptedRequests()
        public
        view
        returns (Builder.Request[] memory)
    {
        Builder.Request[] memory allRequests;
        uint256 counter = 0;

        for (uint256 i = 0; i < customers.length; i++) {
            uint256 customerBalance = requestsByAddress[customers[i]].length;
            if (customerBalance > 0) {
                for (uint256 j = 0; j < customerBalance; j++) {
                    Builder.Request memory request = requests[customers[i]][
                        requestsByAddress[customers[i]][j]
                    ];

                    if (request.isValid && request.accepted) {
                        allRequests[counter] = request;
                        counter++;
                    }
                }
            }
        }

        return allRequests;
    }

    function getUndeployedRequests()
        public
        view
        returns (Builder.Request[] memory)
    {
        Builder.Request[] memory allRequests;
        uint256 counter = 0;

        for (uint256 i = 0; i < customers.length; i++) {
            uint256 customerBalance = requestsByAddress[customers[i]].length;
            if (customerBalance > 0) {
                for (uint256 j = 0; j < customerBalance; j++) {
                    Builder.Request memory request = requests[customers[i]][
                        requestsByAddress[customers[i]][j]
                    ];

                    if (
                        request.isValid && request.accepted && !request.deployed
                    ) {
                        allRequests[counter] = request;
                        counter++;
                    }
                }
            }
        }

        return allRequests;
    }

    function changeTokenReceiver(address _receiver)
        public
        onlyRole(ROLE_ADMIN)
    {
        tokenReceiver = _receiver;
    }

    function changeState(bool newState) public onlyRole(ROLE_ADMIN) {
        open = newState;
    }

    function changeBuildPrice(uint256 newPrice) public onlyRole(ROLE_ADMIN) {
        buildPrice = newPrice;
    }

    function changeRequestState(
        address owner,
        uint256 id,
        bool isValid,
        bool accepted,
        bool deployed
    ) public onlyRole(ROLE_ADMIN) {
        requests[owner][id].isValid = isValid;
        requests[owner][id].accepted = accepted;
        requests[owner][id].deployed = deployed;
        emit ChangeRequestState(requests[owner][id]);
    }

    function addNewRequest(string memory imageUrl) public {
        require(token.balanceOf(msg.sender) > buildPrice, INVALID_TOKENS);

        require(
            token.transferFrom(msg.sender, address(this), buildPrice),
            INVALID_PAYMENT
        );

        if (!requestCustomers[msg.sender]) {
            customers.push(msg.sender);
            requestCustomers[msg.sender] = true;
        }

        uint256 requestId = requestsByAddress[msg.sender].length;

        Builder.Request memory request = Builder.Request(
            requestId,
            msg.sender,
            imageUrl,
            true,
            false,
            false
        );

        requests[msg.sender][requestId] = request;
        requestsByAddress[msg.sender].push(requestId);

        emit AddNewRequest(request);
    }

    function withdrawFees() public onlyRole(ROLE_ADMIN) {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, INVALID_TOKENS);
        require(creator != address(0), INVALID_ADDRESS);
        require(tokenReceiver != address(0), INVALID_ADDRESS);
        token.transfer(creator, (balance * (100 - CREATOR_FEE)) / 100);
        token.transfer(tokenReceiver, (balance * (100 - LIQUIDITY_FEE)) / 100);
    }
}
