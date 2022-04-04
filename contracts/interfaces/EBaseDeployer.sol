// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

struct DeployerData {
    uint8[] buildTypes;
    uint8[] buildModels;
    uint16[] typeProbabilities;
    uint16 probabilitiesTotal;
}

abstract contract EBaseDeployer is Initializable, AccessControl {
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    uint16[] public typeProbabilities = [1, 5, 10, 30, 54];
    uint8[] public buildTypes = [1, 2, 3, 4, 5];
    uint8[] public buildModels = [1, 2, 3, 4];

    string public constant INVALID_LENGTH = "BD: Invalid legth";
    string public constant INVALID_TYPE = "BD: Invalid type";
    string public constant INVALID_MODEL = "BD: Invalid model";

    // Getters

    function getBuildTypes() public view virtual returns (uint8[] memory);

    function getBuildModels() public view virtual returns (uint8[] memory);

    function getTypeProbabilities()
        public
        view
        virtual
        returns (uint16[] memory);

    function getTypeProbability(uint8 build)
        public
        view
        virtual
        returns (uint16);

    function probabilitiesTotal(uint16[] memory probabilities)
        public
        pure
        virtual
        returns (uint16);

    function getProbabilitiesTotal() public view virtual returns (uint16);

    function getData() external view virtual returns (DeployerData memory);

    function getEmployeePoints(uint8 employee)
        public
        view
        virtual
        returns (uint16);

    function calcEmployeePoints(uint8[4] memory parts)
        public
        view
        virtual
        returns (uint16);

    function updateAlterator(uint16 _alter) external virtual;

    function addBuildTypes(uint8 build, uint16 probability) external virtual;

    function removeBuildTypes(uint8 build) external virtual;

    function addBuildModel(uint8 model) external virtual;

    function removeBuildModel(uint8 model) external virtual;

    // Generators

    function randomBuildType() external virtual returns (uint8);

    function randomBuildTypes(uint256 count)
        external
        virtual
        returns (uint8[] memory);

    function randomTypeByProbabilities(uint16[] memory probabilities)
        external
        virtual
        returns (uint8);

    function randomModel() external virtual returns (uint8);

    function typeByRandom(uint256 random, uint16[] memory probabilities)
        public
        view
        virtual
        returns (uint8);

    function newRandom(uint256 min, uint256 max)
        public
        virtual
        returns (uint256);

    function newRandomBatch(
        uint256 min,
        uint256 max,
        uint256 count
    ) public virtual returns (uint256[] memory);

    // Questions
    function isValidType(uint8 reqType) external view virtual returns (bool);

    function isValidModel(uint8 model) external view virtual returns (bool);
}
