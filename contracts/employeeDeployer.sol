// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./libraries/employee.sol";
import "./employee.sol";
import "./interfaces/EBaseDeployer.sol";

contract EmployeeDeployer is Initializable, AccessControl {
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_TYPE = "ED: Invalid employee type";
    string public constant INVALID_PAYMENT = "ED: Invalid payment";
    string public constant INVALID_LENGTH = "ED: Invalid length";
    string public constant INVALID_CREATOR = "ED: Invalid creator";
    string public constant INVALID_EMPLOYEE_POOL = "ED: Invalid employee pool";
    string public constant INVALID_PLAY_TO_EARN = "ED: Invalid play to earn";
    string public constant INVALID_NFT_STAKING = "ED: Invalid nft staking";
    string public constant INVALID_DEPLOYMENT = "ED: Invalid deplyment";
    string public constant INVALID_FEES = "ED: Invalid fees";

    uint8 public creatorFee = 5;
    uint8 public playToEarnFee = 95;

    uint256 public employeePrice = 10000000000000000000000 wei;
    uint16 public maxDeployments = 1000;

    IERC20 private token;
    Employees private employees;
    EBaseDeployer private baseDeployer;

    address public creator;
    address public playToEarnPool;

    function initialize(
        address _token,
        address _baseDeployer,
        address _employees
    ) external initializer {
        _setupRole(MAIN_OWNER, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        creator = msg.sender;

        token = IERC20(_token);
        employees = Employees(_employees);
        baseDeployer = EBaseDeployer(_baseDeployer);
    }

    // Getters

    function getEmployeesData()
        external
        view
        returns (EmployeeLibrary.EmployeesData memory)
    {
        return
            EmployeeLibrary.EmployeesData(
                employeePrice,
                creatorFee,
                playToEarnFee
            );
    }

    // Setters

    function changeRedirectAddresses(address _creator, address _playToEarnPool)
        external
        onlyRole(MAIN_OWNER)
    {
        playToEarnPool = _playToEarnPool;
        creator = _creator;
    }

    function changeFees(uint8 _playToEarn, uint8 _creator)
        external
        onlyRole(MAIN_OWNER)
    {
        require((_playToEarn + _creator) == 100, INVALID_FEES);
        creatorFee = _creator;
        playToEarnFee = _playToEarn;
    }

    function setDeployer(address _deployer) external onlyRole(MAIN_OWNER) {
        baseDeployer = EBaseDeployer(_deployer);
    }

    function setEmployeePrice(uint256 _price) external onlyRole(MAIN_OWNER) {
        employeePrice = _price;
    }

    function setMaxDeployments(uint16 max) external onlyRole(MAIN_OWNER) {
        maxDeployments = max;
    }

    // Payment

    function payMint(address customer) private returns (bool) {
        require(creator != address(0), INVALID_CREATOR);
        require(playToEarnPool != address(0), INVALID_PLAY_TO_EARN);

        if (creatorFee > 0) {
            token.transferFrom(
                customer,
                creator,
                (employeePrice * creatorFee) / 100
            );
        }

        if (playToEarnFee > 0) {
            token.transferFrom(
                customer,
                playToEarnPool,
                (employeePrice * playToEarnFee) / 100
            );
        }

        return true;
    }

    // Alterators

    function mintEmployee(uint8 employeeType) external {
        require(baseDeployer.isValidType(employeeType), INVALID_TYPE);
        require(payMint(msg.sender), INVALID_PAYMENT);

        uint8 head = employeeType;
        uint8[] memory parts = baseDeployer.randomBuildTypes(3);

        employees.mint(
            head,
            parts[0],
            parts[1],
            parts[2],
            baseDeployer.calcEmployeePoints(
                [head, parts[0], parts[1], parts[2]]
            ),
            msg.sender
        );
    }
}
