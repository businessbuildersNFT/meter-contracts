// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/EBaseDeployer.sol";
import "./employee.sol";
import "./multiEmployee.sol";
import "./randomUtil.sol";
import "./employeeExpanded.sol";
import "./interfaces/randoms.sol";

struct MultiEmployeesData {
    uint256 employeePrice;
    uint256 deployerPrice;
    uint8 CREATOR_FEE;
    uint8 LIQUIDITY_AGREGATOR_FEE;
}

contract MultiEmployeeDeployer is Initializable, AccessControl {
    event Mint(address owner, uint256 id, uint256 time);
    event Randomize(uint256 time, address customer);

    event TransferValues(
        uint256 amount,
        uint256 ftb,
        address admin,
        uint256 time
    );

    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_TYPE = "ED: Invalid employee type";
    string public constant INVALID_PAYMENT = "ED: Invalid payment";
    string public constant INVALID_LENGTH = "ED: Invalid length";
    string public constant INVALID_CREATOR = "ED: Invalid creator";
    string public constant INVALID_LIQUIDITY = "ED: Invalid liquidity";
    string public constant INVALID_ADDRESS = "ED: Invalid Address";
    string public constant INVALID_EMPLOYEES = "ED: You need more employees";
    string public constant INVALID_DEPLOYMENT = "ED: Invalid deployment";

    uint8 public constant CREATOR_DEPOSIT_FEES = 15;
    uint8 public constant LIQUIDITY_AGREGATOR_FEE = 85;
    uint8 public constant NEED_EMPLOYEES = 5;

    uint16 public totalDeployments = 0;
    uint16 public maxDeployments = 56;

    uint256 public employeePrice = 80000000000000000000000 wei;
    uint256 public deployerPrice = 100000000000000000000 wei;
    uint256 public randomizePrice = 10000000000000000000 wei;

    mapping(address => bool) private usedAddress;

    IERC20 private token;
    IERC20 private specialToken;
    Employees private employees;
    MultiEmployees private multiEmployees;
    EBaseDeployer private baseDeployer;
    EmployeesExpanded private employeeExpanded;

    address public creator;
    address public liquidityAgregator;

    uint16 private _randomCounter = 1;

    function initialize(
        address _token,
        address _baseDeployer,
        address _employees,
        address _multiEmployees,
        address _employeeExpanded
    ) external initializer {
        _setupRole(MAIN_OWNER, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        creator = msg.sender;

        token = IERC20(_token);
        employees = Employees(_employees);
        multiEmployees = MultiEmployees(_multiEmployees);
        baseDeployer = EBaseDeployer(_baseDeployer);
        employeeExpanded = EmployeesExpanded(_employeeExpanded);
    }

    function changeBaseDeployer(address _deployer)
        external
        onlyRole(MAIN_OWNER)
    {
        baseDeployer = EBaseDeployer(_deployer);
    }

    function changeSpecialToken(address _token) external onlyRole(MAIN_OWNER) {
        specialToken = IERC20(_token);
    }

    // Getters

    function getEmployeesData()
        external
        view
        returns (MultiEmployeesData memory)
    {
        return
            MultiEmployeesData(
                employeePrice,
                deployerPrice,
                CREATOR_DEPOSIT_FEES,
                LIQUIDITY_AGREGATOR_FEE
            );
    }

    function validMultiEmployeeOwner(address owner)
        external
        view
        returns (bool)
    {
        return usedAddress[owner];
    }

    // Setters

    function changeRedirectAddresses(
        address _creator,
        address _liquidityAgregator
    ) external onlyRole(MAIN_OWNER) {
        liquidityAgregator = _liquidityAgregator;
        creator = _creator;
    }

    function setMaxDeployments(uint16 deployments)
        external
        onlyRole(MAIN_OWNER)
    {
        maxDeployments = deployments;
    }

    function useAddress(address owner) external onlyRole(MAIN_OWNER) {
        usedAddress[owner] = true;
    }

    function changePrice(
        uint256 _minter,
        uint256 _employee,
        uint256 _randomize
    ) external onlyRole(MAIN_OWNER) {
        employeePrice = _employee;
        deployerPrice = _minter;
        randomizePrice = _randomize;
    }

    // Alterators

    function mintEmployee() external payable {
        require(totalDeployments <= maxDeployments, INVALID_DEPLOYMENT);

        require(creator != address(0), INVALID_CREATOR);
        require(liquidityAgregator != address(0), INVALID_LIQUIDITY);

        require(msg.sender != address(0), INVALID_ADDRESS);
        require(!usedAddress[msg.sender], INVALID_ADDRESS);

        uint8 usedEmployee = 0;

        for (uint256 i = 0; i < employees.balanceOf(msg.sender); i++) {
            uint256 employee = employees.tokenOfOwnerByIndex(msg.sender, i);
            if (usedEmployee == NEED_EMPLOYEES) break;
            else {
                if (!employeeExpanded.isUsedForMultiEmployee(employee)) {
                    employeeExpanded.useForMultiEmployee(employee, true);
                    usedEmployee++;
                }
            }
        }

        require(usedEmployee == NEED_EMPLOYEES, INVALID_EMPLOYEES);
        require(msg.value == deployerPrice, INVALID_PAYMENT);
        require(token.balanceOf(msg.sender) >= employeePrice, INVALID_PAYMENT);

        token.transferFrom(msg.sender, (address(this)), employeePrice);

        uint8 buildType = baseDeployer.randomBuildType();

        multiEmployees.mint(
            buildType,
            buildType,
            buildType,
            buildType,
            baseDeployer.calcEmployeePoints(
                [buildType, buildType, buildType, buildType]
            ),
            msg.sender
        );

        usedAddress[msg.sender] = true;
        totalDeployments++;

        emit Mint(msg.sender, totalDeployments, block.timestamp);
    }

    function transferValues() external onlyRole(MAIN_OWNER) {
        uint256 totalMainToken = address(this).balance;
        uint256 totalFTB = token.balanceOf(address(this));

        payable(liquidityAgregator).transfer(
            (totalMainToken * LIQUIDITY_AGREGATOR_FEE) / 100
        );

        payable(creator).transfer(
            (totalMainToken * CREATOR_DEPOSIT_FEES) / 100
        );

        token.transfer(
            liquidityAgregator,
            (totalFTB * LIQUIDITY_AGREGATOR_FEE) / 100
        );

        token.transfer(creator, (totalFTB * CREATOR_DEPOSIT_FEES) / 100);

        emit TransferValues(
            totalMainToken,
            totalFTB,
            msg.sender,
            block.timestamp
        );
    }

    function randomize() external onlyRole(MAIN_OWNER) {
        uint256 totalEmployees = multiEmployees.totalSupply();
        uint8[] memory buildTypes = baseDeployer.getBuildTypes();

        uint256[] memory manyRandoms = baseDeployer.newRandomBatch(
            0,
            buildTypes.length - 1,
            totalEmployees
        );

        for (uint256 i = 0; i < manyRandoms.length; i++) {
            multiEmployees.alterEmployeeType(
                multiEmployees.tokenByIndex(i),
                buildTypes[manyRandoms[i]],
                baseDeployer.calcEmployeePoints(
                    [
                        buildTypes[manyRandoms[i]],
                        buildTypes[manyRandoms[i]],
                        buildTypes[manyRandoms[i]],
                        buildTypes[manyRandoms[i]]
                    ]
                )
            );
        }

        emit Randomize(block.timestamp, address(0));
    }

    function radomizeMyEmployees() external {
        require(address(specialToken) != address(0), INVALID_ADDRESS);
        uint256 _balance = multiEmployees.balanceOf(msg.sender);
        require(_balance > 0, INVALID_LENGTH);

        require(
            specialToken.balanceOf(msg.sender) >= randomizePrice,
            INVALID_PAYMENT
        );

        if (randomizePrice > 0) {
            specialToken.transferFrom(
                msg.sender,
                liquidityAgregator,
                randomizePrice
            );
        }

        uint8[] memory buildTypes = baseDeployer.getBuildTypes();

        uint256[] memory manyRandoms = baseDeployer.newRandomBatch(
            0,
            buildTypes.length - 1,
            _balance
        );

        for (uint256 i = 0; i < _balance; i++) {
            multiEmployees.alterEmployeeType(
                multiEmployees.tokenOfOwnerByIndex(msg.sender, i),
                buildTypes[manyRandoms[i]],
                baseDeployer.calcEmployeePoints(
                    [
                        buildTypes[manyRandoms[i]],
                        buildTypes[manyRandoms[i]],
                        buildTypes[manyRandoms[i]],
                        buildTypes[manyRandoms[i]]
                    ]
                )
            );
        }

        emit Randomize(block.timestamp, msg.sender);
    }
}
