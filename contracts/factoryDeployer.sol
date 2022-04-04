// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./libraries/factory.sol";
import "./interfaces/EBaseDeployer.sol";
import "./employee.sol";
import "./factory.sol";
import "./cityRelationsStorage.sol";

contract FactoryDeployer is Initializable, AccessControl {
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_TYPE = "FD: Invalid factory type";
    string public constant INVALID_PAYMENT = "FD: Invalid payment";
    string public constant INVALID_CREATOR = "FD: Invalid creator";
    string public constant INVALID_EMPLOYEE_POOL = "FD: Invalid employee pool";
    string public constant INVALID_PLAY_TO_EARN = "FD: Invalid play to earn";
    string public constant INVALID_NFT_STAKING = "FD: Invalid nft staking";
    string public constant INVALID_OWNER = "FD: Invalid owner";
    string public constant INVALID_EMPLOYEE_SEED = "FD: Invalid employee seed";
    string public constant INVALID_NFT = "FD: Invalid nft";
    string public constant INVALID_NFT_TYPES = "FD: Invalid nft types";
    string public constant INVALID_FEES = "FD: Invalid fee";

    uint8 public creatorFee = 5;
    uint8 public playToEarnFee = 95;

    uint8 public constant EMPLOYEE_BURNER = 5;

    uint256 public factoryPrice = 5000000000000000000000 wei;

    mapping(address => uint8) private whiteList;

    IERC20 private token;
    Factories private factories;
    Employees private employees;
    EBaseDeployer private baseDeployer;

    address public creator;
    address public playToEarnPool;

    function initialize(
        address _token,
        address _baseDeployer,
        address _factories,
        address _employees
    ) public initializer {
        _setupRole(MAIN_OWNER, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        creator = msg.sender;

        token = IERC20(_token);
        factories = Factories(_factories);
        baseDeployer = EBaseDeployer(_baseDeployer);
        employees = Employees(_employees);
    }

    function changeBaseDeployer(address _deployer) public onlyRole(MAIN_OWNER) {
        baseDeployer = EBaseDeployer(_deployer);
    }

    // Getters

    function getFactoriesData()
        external
        view
        returns (FactoryLibrary.FactoriesData memory)
    {
        return
            FactoryLibrary.FactoriesData(
                factoryPrice,
                EMPLOYEE_BURNER,
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

    function setFactoryPrice(uint256 _price) external onlyRole(MAIN_OWNER) {
        factoryPrice = _price;
    }

    function changeFees(uint8 _creatorFee, uint8 _playToEarnFee)
        external
        onlyRole(MAIN_OWNER)
    {
        require(_creatorFee + _playToEarnFee == 100, INVALID_FEES);

        creatorFee = _creatorFee;
        playToEarnFee = _playToEarnFee;
    }

    // Payment

    function pay(address customer, uint256 amount) private returns (bool) {
        require(creator != address(0), INVALID_CREATOR);
        require(playToEarnPool != address(0), INVALID_PLAY_TO_EARN);

        if (creatorFee > 0) {
            token.transferFrom(customer, creator, (amount * creatorFee) / 100);
        }

        if (playToEarnFee > 0) {
            token.transferFrom(
                customer,
                playToEarnPool,
                (amount * playToEarnFee) / 100
            );
        }

        return true;
    }

    // Alterators

    function mintFactory(uint256[] memory ids) external {
        require(ids.length == EMPLOYEE_BURNER, INVALID_EMPLOYEE_SEED);
        require(employees.isOwnerOfAll(msg.sender, ids), INVALID_EMPLOYEE_SEED);
        require(pay(msg.sender, factoryPrice), INVALID_PAYMENT);

        uint8[] memory buildTypes = baseDeployer.getBuildTypes();
        uint16[] memory probabilities = new uint16[](buildTypes.length);
        uint256 totalPoints = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            uint8 employeeType = employees.getType(ids[i]);
            uint16 employeePoints = employees.getPoints(ids[i]);

            for (uint256 j = 0; j < buildTypes.length; j++) {
                if (buildTypes[j] == employeeType) {
                    probabilities[j] += employeePoints;
                    break;
                }
            }

            totalPoints += employeePoints;
            employees.burn(ids[i]);
        }

        factories.mint(
            baseDeployer.randomTypeByProbabilities(probabilities),
            baseDeployer.randomModel(),
            totalPoints,
            msg.sender
        );
    }
}
