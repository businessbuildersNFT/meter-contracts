// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ETeamLeaderValidations.sol";
import "./interfaces/ETeamLeaderValidations.sol";
import "./interfaces/EUniversitiesStorage.sol";
import "./interfaces/ECityRelations.sol";
import "./interfaces/ECityStorage.sol";
import "./libraries/cities.sol";
import "./factory.sol";

contract CityRelationsGetters is Initializable, AccessControl {
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    Factories private factories;
    ECityRelationsStorage private citiesStorage;
    ECityUniversitiesStorage private citiesUniversities;
    ETeamLeaderValidations private teamLeader;

    uint8 public creatorFees = 0;
    uint8 public cityFees = 5;
    uint8 public factoryFees = 10;
    uint8 public playToEarnFees = 100;
    uint8 public rewardsMultiplier = 5;
    uint8 public createRelationBase = 2;
    uint32 public removeTime = 86400;

    function initialize(
        address _factories,
        address _citiesStorage,
        address _citiesUniversities,
        address _teamLeader
    ) external initializer {
        _setupRole(MAIN_OWNER, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        citiesStorage = ECityRelationsStorage(_citiesStorage);
        citiesUniversities = ECityUniversitiesStorage(_citiesUniversities);
        teamLeader = ETeamLeaderValidations(_teamLeader);
        factories = Factories(_factories);
    }

    function changeAddresses(
        address _factories,
        address _citiesStorage,
        address _citiesUniversities,
        address _teamLeader
    ) external onlyRole(MAIN_OWNER) {
        citiesStorage = ECityRelationsStorage(_citiesStorage);
        citiesUniversities = ECityUniversitiesStorage(_citiesUniversities);
        teamLeader = ETeamLeaderValidations(_teamLeader);
        factories = Factories(_factories);
    }

    //Update

    function updateRewardsMultiplier(uint8 _t) external onlyRole(MAIN_OWNER) {
        rewardsMultiplier = _t;
    }

    function updateRelationsBase(uint8 _t) external onlyRole(MAIN_OWNER) {
        createRelationBase = _t;
    }

    function updateFees(
        uint8 _c,
        uint8 _i,
        uint8 _f,
        uint8 _p
    ) external onlyRole(MAIN_OWNER) {
        creatorFees = _c;
        cityFees = _i;
        factoryFees = _f;
        playToEarnFees = _p;
    }

    function updatePenalTime(uint32 _t) external onlyRole(MAIN_OWNER) {
        removeTime = _t;
    }

    // Getters

    function getOwnerRelationRewards(
        uint256 _c,
        uint256 _f,
        address _o
    ) public view returns (uint256) {
        uint256 _rewards = getOwnerTemporalRewards(_c, _f, _o);
        return _rewards + ((_rewards * rewardsMultiplier) / 100);
    }

    function getOwnerTemporalRewards(
        uint256 _c,
        uint256 _f,
        address _o
    ) public view returns (uint256) {
        CitiesLibrary.CityRelation memory _r = citiesStorage.getRelationData(
            _c,
            _f
        );

        CitiesLibrary.FactoryAddition memory _a = citiesStorage
            .getFactoryAddition(_f, _o);

        uint256 _maxMultiplicator = teamLeader.getMaxMultiplicator(_o);

        uint256 _addMultiplicator = calcAddition(
            _a.totalEmployees,
            citiesStorage.augmentEmployees(),
            citiesStorage.maxEmployeeMultiplicator()
        );

        uint256 _multiplicator = _r.multiplicator + _addMultiplicator;

        _multiplicator = _multiplicator > _maxMultiplicator
            ? _maxMultiplicator
            : _multiplicator;

        return
            relationRewards(
                _multiplicator,
                _a.relationPoints + factories.getMultiplier(_f),
                _a.relationPercentage
            ) + _a.entryPayment;
    }

    function getRemoveRelationTime(uint256 _c, uint256 _f)
        public
        view
        returns (uint256)
    {
        return
            citiesStorage.getRelationStartTime(_c, _f) +
            citiesStorage.minTime();
    }

    function getHardEndPrice(uint256 _c, uint256 _f)
        public
        view
        returns (uint256)
    {
        CitiesLibrary.CityRelation memory _relation = citiesStorage
            .getRelationData(_c, _f);
        return
            calculateHardEnd(
                _relation.maxFactoryPoints,
                _relation.momentPrice,
                _relation.banckruptcyProbability
            );
    }

    function getCityRelationProperties(
        uint256 _c,
        uint256 _f,
        address _o
    ) external view returns (CitiesLibrary.CityRelationProperties memory) {
        uint256 _maxFactoryPoints = citiesStorage.relationFactoryBase() *
            factories.getMultiplier(_f);

        uint256 _maxMultiplier = teamLeader.getMaxMultiplicator(_o);
        uint256 _baseMultiplier = citiesUniversities.getBaseCityMultiplier(_c);

        return
            CitiesLibrary.CityRelationProperties(
                _maxFactoryPoints,
                calcRelation(
                    citiesStorage.entryPrice(),
                    _maxFactoryPoints,
                    createRelationBase
                ),
                _baseMultiplier,
                _maxMultiplier,
                _baseMultiplier > _maxMultiplier
                    ? _maxMultiplier
                    : _baseMultiplier
            );
    }

    // Calculations

    function calcAddition(
        uint256 _e,
        uint16 _a,
        uint16 _m
    ) public pure returns (uint256) {
        uint256 _r = _e / _a;
        return _r <= _m ? _r : _m;
    }

    function relationRewards(
        uint256 _m,
        uint256 _p,
        uint256 _r
    ) public pure returns (uint256) {
        return (((_m * _p * _r) * 10**18) / 100);
    }

    function calculateHardEnd(
        uint256 _m,
        uint256 _p,
        uint256 _b
    ) public pure returns (uint256) {
        return ((_m * _p * _b) / 100) / 2;
    }

    function calcNextPrice(uint256 _l, uint16 _a)
        public
        pure
        returns (uint256)
    {
        return _l + ((_l * _a) / 100);
    }

    function calcRelation(
        uint256 _e,
        uint256 _m,
        uint8 _t
    ) public pure returns (uint256) {
        return _m * (((_e * _t) / 100));
    }

    function calcBankrupt(uint256 _p, uint256 _f)
        public
        pure
        returns (uint256)
    {
        return 100 - ((_p * 100) / _f);
    }
}
