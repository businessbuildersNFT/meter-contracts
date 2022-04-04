// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./libraries/employee.sol";
import "./interfaces/EBaseDeployer.sol";
import "./employee.sol";
import "./miniEmployee.sol";
import "./employeeExpanded.sol";

struct SpecialEmployeesChildrensData {
    address specialToken;
    uint256 specialEmployeePrice;
    uint256 specialEmployeeInitPrice;
    uint256 specialEmployeeMaxPrice;
    uint256 specialQuantity;
    uint256 specialAugment;
    bool open;
}

struct EmployeesChildrensData {
    uint256 employeePrice;
    uint16 payedMints;
    uint16 maxPayedMints;
    uint8 packageSize;
    uint8 packageDiscount;
    uint8 maxMerge;
    uint8 creatorFee;
    uint8 playToEarnFee;
    bool validatePayedMints;
}

contract MiniEmployeeDeployer is Initializable, AccessControl {
    event PayMint(address owner, uint256 amount, bool package);
    event StakingMint(address owner, uint256 amount, bool package);
    event Upgrade(address owner, uint256 id, uint16 points);
    event Merge(address owner, uint256 men, uint256 woman);

    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_TYPE = "ED: Invalid employee type";
    string public constant INVALID_PAYMENT = "ED: Invalid payment";
    string public constant INVALID_LENGTH = "ED: Invalid length";
    string public constant INVALID_CREATOR = "ED: Invalid creator";
    string public constant INVALID_OWNER = "ED: Invalid owner";
    string public constant INVALID_EMPLOYEE = "ED: Invalid employee";
    string public constant INVALID_PLAY_TO_EARN = "ED: Invalid play to earn";
    string public constant INVALID_BUY = "ED: Invalid buy";
    string public constant INVALID_MERGE = "ED: Invalid merge";
    string public constant INVALID_XP = "ED: Invalid xp";
    string public constant INVALID_FEES = "ED: Invalid fees";

    uint8 public creatorFee = 5;
    uint8 public playToEarnFee = 95;
    uint8 public maxMerges = 10;
    uint8 public liquidityAgregatorFee = 95;

    bool public validateMaxPayedMints = true;
    bool public openSpecialEmployee = false;

    uint16 public maxPayedMints = 1000;
    uint16 public payedMints = 0;
    uint8 public packageDiscount = 5;
    uint8 public packageSize = 5;

    uint256 public employeePrice = 1000000000000000000000 wei;
    uint256 public specialEmployeePrice = 4000000000000000000 wei;
    uint256 public specialEmployeeMaxPrice = 10000000000000000000 wei;
    uint256 public specialEmployeeInitPrice = 4000000000000000000 wei;

    IERC20 private token;
    IERC20 private specialToken;
    Employees private employees;
    MiniEmployees private miniEmployees;
    EBaseDeployer private baseDeployer;
    EmployeesExpanded private employeeExpanded;

    address public creator;
    address public liquidityAgregator;
    address public playToEarnPool;

    uint256 public specialAugment = 3;
    uint256 public specialQuantity = 1;
    uint256 public specialCounter = 0;

    function initialize(
        address _token,
        address _specialToken,
        address _employees,
        address _baseDeployer,
        address _miniEmployees,
        address _employeeExpanded
    ) external initializer {
        _setupRole(MAIN_OWNER, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        creator = msg.sender;

        token = IERC20(_token);
        specialToken = IERC20(_specialToken);
        employees = Employees(_employees);
        miniEmployees = MiniEmployees(_miniEmployees);
        baseDeployer = EBaseDeployer(_baseDeployer);
        employeeExpanded = EmployeesExpanded(_employeeExpanded);
    }

    // Getters

    function getEmployeesData()
        external
        view
        returns (EmployeesChildrensData memory)
    {
        return
            EmployeesChildrensData(
                employeePrice,
                payedMints,
                maxPayedMints,
                packageSize,
                packageDiscount,
                maxMerges,
                creatorFee,
                playToEarnFee,
                validateMaxPayedMints
            );
    }

    function getSpecialEmployeesData()
        external
        view
        returns (SpecialEmployeesChildrensData memory)
    {
        return
            SpecialEmployeesChildrensData(
                address(specialToken),
                specialEmployeePrice,
                specialEmployeeInitPrice,
                specialEmployeeMaxPrice,
                specialQuantity,
                specialAugment,
                openSpecialEmployee
            );
    }

    // Setters

    function changeRedirectAddresses(
        address _creator,
        address _playToEarnPool,
        address _liquidityAgregator
    ) external onlyRole(MAIN_OWNER) {
        playToEarnPool = _playToEarnPool;
        liquidityAgregator = _liquidityAgregator;
        creator = _creator;
    }

    function changeConfigurations(IERC20 _token, IERC20 _specialToken)
        external
        onlyRole(MAIN_OWNER)
    {
        token = _token;
        specialToken = _specialToken;
    }

    function changeFees(uint8 _creator, uint8 _playToEarn)
        external
        onlyRole(MAIN_OWNER)
    {
        require(_creator + _playToEarn == 100, INVALID_FEES);

        creatorFee = _creator;
        playToEarnFee = _playToEarn;
    }

    function setMaxMerge(uint8 max) external onlyRole(MAIN_OWNER) {
        maxMerges = max;
    }

    function setEmployeePrice(uint256 _price) external onlyRole(MAIN_OWNER) {
        employeePrice = _price;
    }

    function changeSpecialData(
        uint256 price,
        uint256 augment,
        uint256 quantity,
        uint256 initPrice,
        uint256 maxPrice,
        bool open
    ) external onlyRole(MAIN_OWNER) {
        specialEmployeePrice = price;
        specialAugment = augment;
        specialQuantity = quantity;
        specialEmployeeInitPrice = initPrice;
        specialEmployeeMaxPrice = maxPrice;
        openSpecialEmployee = open;
    }

    function setPackageDiscount(uint8 discount) external onlyRole(MAIN_OWNER) {
        packageDiscount = discount;
    }

    function setValidateMaxMints(bool validate) external onlyRole(MAIN_OWNER) {
        validateMaxPayedMints = validate;
    }

    function setPackageSize(uint8 size) external onlyRole(MAIN_OWNER) {
        packageSize = size;
    }

    function setMaxPayedMints(uint16 max) external onlyRole(MAIN_OWNER) {
        maxPayedMints = max;
    }

    // Alterators

    function payMint(
        address customer,
        bool package,
        bool validate,
        uint256 multiplicator
    ) private returns (bool) {
        require(creator != address(0), INVALID_CREATOR);
        require(playToEarnPool != address(0), INVALID_PLAY_TO_EARN);

        require(
            (validate == true && payedMints <= maxPayedMints) ||
                validate == false,
            INVALID_BUY
        );

        uint256 totalAmount = package
            ? (((employeePrice * packageSize) / 100) * (100 - packageDiscount))
            : employeePrice * multiplicator;

        require(token.balanceOf(customer) >= totalAmount, INVALID_PAYMENT);

        if (creatorFee > 0) {
            token.transferFrom(
                customer,
                creator,
                (totalAmount * creatorFee) / 100
            );
        }

        if (playToEarnFee > 0) {
            token.transferFrom(
                customer,
                playToEarnPool,
                (totalAmount * playToEarnFee) / 100
            );
        }

        if (validate) payedMints++;

        emit PayMint(customer, totalAmount, package);

        return true;
    }

    function normalMint() private {
        uint8[] memory parts = baseDeployer.randomBuildTypes(4);

        miniEmployees.mint(
            parts[0],
            parts[1],
            parts[2],
            parts[3],
            0,
            baseDeployer.calcEmployeePoints(
                [parts[0], parts[1], parts[2], parts[3]]
            ),
            msg.sender
        );
    }

    function packageMint() private {
        uint8[] memory parts = baseDeployer.randomBuildTypes(packageSize * 4);

        for (uint8 i = 0; i < packageSize * 4; i += 4) {
            miniEmployees.mint(
                parts[i],
                parts[i + 1],
                parts[i + 2],
                parts[i + 3],
                0,
                baseDeployer.calcEmployeePoints(
                    [parts[i], parts[i + 1], parts[i + 2], parts[i + 3]]
                ),
                msg.sender
            );
        }
    }

    function mintSpecialEmployee() external {
        require(openSpecialEmployee, INVALID_BUY);
        require(creator != address(0), INVALID_CREATOR);

        require(
            specialToken.balanceOf(msg.sender) >= specialEmployeePrice,
            INVALID_PAYMENT
        );

        if (creatorFee > 0) {
            specialToken.transferFrom(
                msg.sender,
                creator,
                (specialEmployeePrice * creatorFee) / 100
            );
        }

        if (liquidityAgregatorFee > 0) {
            specialToken.transferFrom(
                msg.sender,
                liquidityAgregator,
                (specialEmployeePrice * liquidityAgregatorFee) / 100
            );
        }

        uint8[] memory parts = baseDeployer.randomBuildTypes(3);

        miniEmployees.mint(
            parts[0],
            parts[1],
            parts[2],
            parts[0],
            1,
            baseDeployer.calcEmployeePoints(
                [parts[0], parts[1], parts[2], parts[0]]
            ),
            msg.sender
        );

        specialCounter++;

        if (specialCounter == specialQuantity) {
            specialEmployeePrice += ((specialEmployeePrice * specialAugment) /
                100);

            specialCounter = 0;
        }

        if (specialEmployeePrice >= specialEmployeeMaxPrice) {
            specialEmployeePrice = specialEmployeeInitPrice;
        }
    }

    function mintPayedEmployee(bool package) external {
        require(payMint(msg.sender, package, true, 1), INVALID_PAYMENT);
        if (package) packageMint();
        else normalMint();
    }

    function upgradeEmployee(uint256 miniEmployee) external {
        require(miniEmployees.validate(miniEmployee), INVALID_EMPLOYEE);

        require(
            miniEmployees.ownerOf(miniEmployee) == msg.sender,
            INVALID_OWNER
        );

        uint16 points = miniEmployees.getPoints(miniEmployee);

        require(miniEmployees.getXP(miniEmployee) >= points * 100, INVALID_XP);

        uint8[4] memory parts = miniEmployees.getParts(miniEmployee);

        employees.mint(
            parts[0],
            parts[1],
            parts[2],
            parts[3],
            points,
            msg.sender
        );

        miniEmployees.burn(miniEmployee);

        emit Upgrade(msg.sender, miniEmployee, points);
    }

    function mergeTwoEmployees(uint256 men, uint256 woman) external {
        require(
            employees.ownerOf(men) == msg.sender &&
                employees.ownerOf(woman) == msg.sender,
            INVALID_OWNER
        );

        require(
            employees.validate(men) && employees.validate(woman),
            INVALID_EMPLOYEE
        );

        require(employeeExpanded.canMerge(men), INVALID_MERGE);
        require(employeeExpanded.canMerge(woman), INVALID_MERGE);

        require(payMint(msg.sender, false, false, 1), INVALID_PAYMENT);

        uint256 random = baseDeployer.newRandom(0, 99);
        uint8 employeeType = employees.getType(men);

        if (random < 50) employeeType = employees.getType(woman);

        uint8[] memory parts = baseDeployer.randomBuildTypes(3);

        miniEmployees.mint(
            employeeType,
            parts[0],
            parts[1],
            parts[2],
            0,
            baseDeployer.calcEmployeePoints(
                [employeeType, parts[0], parts[1], parts[2]]
            ),
            msg.sender
        );

        employeeExpanded.addMerge(men, 1);
        employeeExpanded.addMerge(woman, 1);

        emit Merge(msg.sender, men, woman);
    }

    function mergeTwoEmployeesManyTimes(
        uint256 men,
        uint256 woman,
        uint8 times
    ) external {
        require(
            employees.ownerOf(men) == msg.sender &&
                employees.ownerOf(woman) == msg.sender,
            INVALID_OWNER
        );

        require(
            times + employeeExpanded.getMergeRecord(men) <=
                employeeExpanded.maxMerges(),
            INVALID_MERGE
        );

        require(
            times + employeeExpanded.getMergeRecord(woman) <=
                employeeExpanded.maxMerges(),
            INVALID_MERGE
        );

        require(
            employees.validate(men) && employees.validate(woman),
            INVALID_EMPLOYEE
        );

        require(payMint(msg.sender, false, false, times), INVALID_PAYMENT);

        uint256[] memory randoms = baseDeployer.newRandomBatch(0, 99, times);
        uint8 employeeType = employees.getType(men);

        for (uint256 i = 0; i < randoms.length; i++) {
            if (randoms[i] < 50) employeeType = employees.getType(woman);
            uint8[] memory parts = baseDeployer.randomBuildTypes(3);

            miniEmployees.mint(
                employeeType,
                parts[0],
                parts[1],
                parts[2],
                0,
                baseDeployer.calcEmployeePoints(
                    [employeeType, parts[0], parts[1], parts[2]]
                ),
                msg.sender
            );

            emit Merge(msg.sender, men, woman);
        }

        employeeExpanded.addMerge(men, times);
        employeeExpanded.addMerge(woman, times);
    }
}
