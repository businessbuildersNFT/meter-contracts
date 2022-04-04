// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/EBaseDeployer.sol";
import "./interfaces/randoms.sol";
import "./randomUtil.sol";

contract BaseDeployer is EBaseDeployer {
    bool private _resolveRandom = false;
    uint16 private _randomCounter = 1;
    uint16 private _randomAlterator = 50;

    Randoms private randoms;

    function initialize(address _randoms) external initializer {
        _setupRole(MAIN_OWNER, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        randoms = Randoms(_randoms);
        if (_resolveRandom) randoms.requestRandomNumber();
    }

    function addToCounter() private {
        if (_randomCounter < _randomAlterator) {
            _randomCounter++;
        } else {
            _randomCounter = 0;
            if (_resolveRandom) randoms.requestRandomNumber();
        }
    }

    // Getters

    function getBuildTypes() public view override returns (uint8[] memory) {
        return buildTypes;
    }

    function getBuildModels() public view override returns (uint8[] memory) {
        return buildModels;
    }

    function getTypeProbabilities()
        public
        view
        override
        returns (uint16[] memory)
    {
        return typeProbabilities;
    }

    function getTypeProbability(uint8 build)
        public
        view
        override
        returns (uint16)
    {
        require(isValidType(build), INVALID_TYPE);

        uint16 probability = 0;

        for (uint256 i = 0; i < buildTypes.length; i++) {
            if (build == buildTypes[i]) {
                probability = typeProbabilities[i];
                break;
            }
        }

        return probability;
    }

    function probabilitiesTotal(uint16[] memory probabilities)
        public
        pure
        override
        returns (uint16)
    {
        uint16 adds = 0;

        for (uint8 i = 0; i < probabilities.length; i++) {
            adds += probabilities[i];
        }

        return adds;
    }

    function getProbabilitiesTotal() public view override returns (uint16) {
        return probabilitiesTotal(typeProbabilities);
    }

    function getData() public view override returns (DeployerData memory) {
        return
            DeployerData(
                buildTypes,
                buildModels,
                typeProbabilities,
                probabilitiesTotal(typeProbabilities)
            );
    }

    function getEmployeePoints(uint8 employee)
        public
        view
        override
        returns (uint16)
    {
        return getProbabilitiesTotal() / getTypeProbability(employee);
    }

    function calcEmployeePoints(uint8[4] memory parts)
        public
        view
        override
        returns (uint16)
    {
        uint16 points = 1;

        for (uint8 i = 0; i < parts.length; i++) {
            if (parts[i] == parts[0] && i != 0) {
                points += getEmployeePoints(parts[i]);
            }
        }

        return points;
    }

    // Alterators

    function updateAlterator(uint16 _alter)
        external
        override
        onlyRole(MAIN_OWNER)
    {
        _randomAlterator = _alter;
    }

    function addBuildTypes(uint8 build, uint16 probability)
        external
        override
        onlyRole(MAIN_OWNER)
    {
        require(!isValidType(build), INVALID_TYPE);

        buildTypes.push(build);
        typeProbabilities.push(probability);
    }

    function removeBuildTypes(uint8 build)
        external
        override
        onlyRole(MAIN_OWNER)
    {
        require(isValidType(build), INVALID_TYPE);

        for (uint256 i = 0; i < buildTypes.length; i++) {
            if (build == buildTypes[i]) {
                buildTypes[i] = buildTypes[buildTypes.length - 1];

                typeProbabilities[i] = typeProbabilities[
                    typeProbabilities.length - 1
                ];

                buildTypes.pop();
                typeProbabilities.pop();
                break;
            }
        }
    }

    function addBuildModel(uint8 model) external override onlyRole(MAIN_OWNER) {
        require(!isValidModel(model), INVALID_MODEL);
        buildModels.push(model);
    }

    function removeBuildModel(uint8 model)
        external
        override
        onlyRole(MAIN_OWNER)
    {
        require(isValidModel(model), INVALID_MODEL);

        for (uint256 i = 0; i < buildModels.length; i++) {
            if (model == buildModels[i]) {
                buildModels[i] = buildModels[buildModels.length - 1];
                buildModels.pop();
                break;
            }
        }
    }

    // Generators

    function randomBuildType() external override returns (uint8) {
        return
            typeByRandom(
                newRandom(0, getProbabilitiesTotal()),
                typeProbabilities
            );
    }

    function randomBuildTypes(uint256 count)
        external
        override
        returns (uint8[] memory)
    {
        uint8[] memory types = new uint8[](count);

        uint256[] memory random = newRandomBatch(
            1,
            getProbabilitiesTotal(),
            count
        );

        for (uint256 i = 0; i < count; i++) {
            types[i] = typeByRandom(random[i], typeProbabilities);
        }

        return types;
    }

    function randomTypeByProbabilities(uint16[] memory probabilities)
        external
        override
        returns (uint8)
    {
        require(probabilities.length == buildTypes.length, INVALID_LENGTH);

        return
            typeByRandom(
                newRandom(1, probabilitiesTotal(probabilities)),
                probabilities
            );
    }

    function randomModel() external override returns (uint8) {
        uint8 model = buildModels[newRandom(0, buildModels.length - 1)];
        require(isValidModel(model), INVALID_MODEL);
        return model;
    }

    function typeByRandom(uint256 random, uint16[] memory probabilities)
        public
        view
        override
        returns (uint8)
    {
        uint256 momentAdd = 0;
        uint8 build = buildTypes[buildTypes.length - 1];

        for (uint256 i = 0; i < probabilities.length; i++) {
            uint256 nextAdd = (momentAdd + probabilities[i]);
            if (momentAdd <= random && random <= nextAdd) return buildTypes[i];
            momentAdd += probabilities[i];
        }

        require(isValidType(build), INVALID_TYPE);

        return build;
    }

    // Randoms

    function newRandom(uint256 min, uint256 max)
        public
        override
        returns (uint256)
    {
        uint256 random = RandomUtil.randomSeededMinMax(
            min,
            max,
            randoms.getRandomSeed(msg.sender),
            _randomCounter
        );

        addToCounter();

        return random;
    }

    function newRandomBatch(
        uint256 min,
        uint256 max,
        uint256 count
    ) public override returns (uint256[] memory) {
        uint256[] memory randomSeed = (
            RandomUtil.expandedRandomSeededMinMax(
                min,
                max,
                randoms.getRandomSeed(msg.sender),
                _randomCounter,
                count
            )
        );

        addToCounter();

        return randomSeed;
    }

    // Questions
    function isValidType(uint8 reqType) public view override returns (bool) {
        bool isType = false;
        for (uint256 i = 0; i < buildTypes.length; i++) {
            if (buildTypes[i] == reqType) {
                isType = true;
                break;
            }
        }
        return isType;
    }

    function isValidModel(uint8 model) public view override returns (bool) {
        bool isType = false;
        for (uint256 i = 0; i < buildModels.length; i++) {
            if (buildModels[i] == model) {
                isType = true;
                break;
            }
        }
        return isType;
    }
}
