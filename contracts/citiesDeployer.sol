// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ECityStorage.sol";
import "./interfaces/EBaseDeployer.sol";
import "./libraries/cities.sol";
import "./factory.sol";
import "./cities.sol";

contract CitiesDeployer is Initializable, AccessControl {
    event UpgradeCity(uint256 id);
    event RemoveCity(uint256 id);
    event AddUniversity(uint256 id);
    event AddTownHall(uint256 id);

    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_QUANTITY = "CD: Invalid factories quantity";
    string public constant INVALID_OWNER = "CD: Invalid owner";
    string public constant INVALID_PAYMENT = "CD: Invalid payment";
    string public constant INVALID_ADDRESS = "CD: Invalid address";
    string public constant INVALID_FEES = "CD: Invalid fees";
    string public constant INVALID_FACTORY_STATE = "CD: Invalid factory state";
    string public constant INVALID_CITY_STATE = "CD: Invalid city state";

    Factories private factories;
    Cities private cities;
    IERC20 private token;
    ECityRelationsStorage private citiesStorage;
    EBaseDeployer private baseDeployer;

    uint8 public creatorFee = 5;
    uint8 public playToEarnFee = 95;
    uint8 public availableWorld = 1;
    uint8 public maxUniversityMultiplicator = 50;
    uint8 public minUniversityMultiplicator = 20;
    uint16 public pointsPerLand = 20;
    uint256 public townHallPrice = 100000000000000000000000 wei;
    uint256 public universityPrice = 100000000000000000000000 wei;

    address creator;
    address playToEarn;

    function initialize(
        address _token,
        address _factories,
        address _cities,
        address _citiesStorage,
        address _baseDeployer
    ) public initializer {
        _setupRole(MAIN_OWNER, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        creator = _msgSender();
        factories = Factories(_factories);
        cities = Cities(_cities);
        token = IERC20(_token);
        citiesStorage = ECityRelationsStorage(_citiesStorage);
        baseDeployer = EBaseDeployer(_baseDeployer);
    }

    function updateBaseDeployer(address _deployer) public onlyRole(MAIN_OWNER) {
        baseDeployer = EBaseDeployer(_deployer);
    }

    // Getters

    function getData() external view returns (CitiesLibrary.CitiesData memory) {
        return
            CitiesLibrary.CitiesData(
                creatorFee,
                playToEarnFee,
                pointsPerLand,
                townHallPrice,
                universityPrice
            );
    }

    // Setters

    function setPlayToEarnPool(address _p2e) external onlyRole(MAIN_OWNER) {
        playToEarn = _p2e;
    }

    function setPointsPerLand(uint16 _points) external onlyRole(MAIN_OWNER) {
        pointsPerLand = _points;
    }

    function setTownHallPrice(uint256 _price) external onlyRole(MAIN_OWNER) {
        townHallPrice = _price;
    }

    function setUniversityPrice(uint256 _price) external onlyRole(MAIN_OWNER) {
        universityPrice = _price;
    }

    function changeFees(uint8 _playToEarn, uint8 _creator)
        external
        onlyRole(MAIN_OWNER)
    {
        require(creatorFee + playToEarnFee == 100, INVALID_FEES);

        creatorFee = _creator;
        playToEarnFee = _playToEarn;
    }

    function changePlayToEarnPool(address _playToEarn)
        external
        onlyRole(MAIN_OWNER)
    {
        playToEarn = _playToEarn;
    }

    // Alterators

    function mintCity(string calldata _name, uint256[] memory _factories)
        external
    {
        require(_factories.length > 0, INVALID_QUANTITY);
        require(
            factories.isOwnerOfAll(_msgSender(), _factories),
            INVALID_OWNER
        );

        uint256 totalPoints = 0;

        for (uint256 i = 0; i < _factories.length; i++) {
            require(
                !citiesStorage.getFactoryState(_factories[i]),
                INVALID_FACTORY_STATE
            );

            totalPoints += factories.getMultiplier(_factories[i]);
            factories.burn(_factories[i]);
        }

        cities.mint(
            totalPoints,
            availableWorld,
            _name,
            pointsPerLand,
            _msgSender()
        );
    }

    function addFactoryPoints(uint256 city, uint256[] memory _factories)
        external
    {
        require(_factories.length > 0, INVALID_QUANTITY);
        require(
            factories.isOwnerOfAll(_msgSender(), _factories),
            INVALID_OWNER
        );
        require(cities.ownerOf(city) == _msgSender(), INVALID_OWNER);

        uint256 totalPoints = 0;

        for (uint256 i = 0; i < _factories.length; i++) {
            require(
                !citiesStorage.getFactoryState(_factories[i]),
                INVALID_FACTORY_STATE
            );

            totalPoints += factories.getMultiplier(_factories[i]);
            factories.burn(_factories[i]);
        }

        cities.addPoints(city, totalPoints, pointsPerLand);

        emit UpgradeCity(city);
    }

    function mergeCities(uint256 _base, uint256 _toBurn) external {
        require(
            cities.ownerOf(_base) == _msgSender() &&
                cities.ownerOf(_toBurn) == _msgSender(),
            INVALID_OWNER
        );

        require(
            citiesStorage.getTotalCityRelations(_toBurn) == 0,
            INVALID_CITY_STATE
        );

        cities.addPoints(_base, cities.getPoints(_toBurn), pointsPerLand);
        cities.burn(_toBurn);

        emit UpgradeCity(_base);
        emit RemoveCity(_toBurn);
    }

    function addUniversity(uint256 city) external {
        require(cities.ownerOf(city) == _msgSender(), INVALID_OWNER);
        require(payment(_msgSender(), universityPrice));
        cities.changeUniversityState(city, 1);
        emit AddUniversity(city);
    }

    function addTownHall(uint256 _city) external {
        require(cities.ownerOf(_city) == _msgSender(), INVALID_OWNER);
        require(payment(_msgSender(), townHallPrice));
        cities.changeTownHallState(_city, 1);
        emit AddTownHall(_city);
    }

    function addSpecialUniversity(uint256 _city, uint256 _university)
        external
        onlyRole(MAIN_OWNER)
    {
        cities.changeUniversityState(_city, _university);
        emit AddUniversity(_city);
    }

    function addSpecialTownHall(uint256 _city, uint256 _townHall)
        external
        onlyRole(MAIN_OWNER)
    {
        cities.changeTownHallState(_city, _townHall);
        emit AddTownHall(_city);
    }

    // Payment

    function payment(address owner, uint256 amount) private returns (bool) {
        require(playToEarn != address(0), INVALID_ADDRESS);
        require(creator != address(0), INVALID_ADDRESS);

        if (playToEarnFee > 0) {
            require(
                token.transferFrom(
                    owner,
                    playToEarn,
                    (amount * playToEarnFee) / 100
                ),
                INVALID_PAYMENT
            );
        }

        if (creatorFee > 0) {
            require(
                token.transferFrom(owner, creator, (amount * creatorFee) / 100),
                INVALID_PAYMENT
            );
        }

        return true;
    }

    function randomizeUniversityMultiplier() external onlyRole(MAIN_OWNER) {
        uint256 _citiesSupply = cities.totalSupply();

        uint256[] memory _randoms = baseDeployer.newRandomBatch(
            minUniversityMultiplicator,
            maxUniversityMultiplicator,
            _citiesSupply
        );

        for (uint256 i = 0; i < _randoms.length; i++) {
            uint256 _cityID = cities.tokenByIndex(i);
            citiesStorage.changeUniversityMultiplicator(
                _cityID,
                _randoms[i] * 10**18
            );
        }
    }
}
