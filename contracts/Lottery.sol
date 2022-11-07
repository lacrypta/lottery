// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {ILottery} from "./ILottery.sol";

/**
 * Blockchain-based Lottery Implementation
 *
 * This Lottery implementation uses iterated Keccak256 as the underlying RNG.
 *
 */
contract Lottery is ILottery {

    /**
     * Mapping from hashed lottery name to lottery configuration
     *
     */
    mapping(bytes32 => Config) internal _lotteries;

    /**
     * Determine whether the given lottery name exists
     *
     * @param name  Lottery name to check
     * @return existing  True if the given lottery name exists, false otherwise
     */
    function exists(string memory name) external view override returns (bool existing) {
        existing = (0 != _lotteries[_nameHash(name)].players.length);
    }

    /**
     * Retrieve an existing lottery by name
     *
     * @param name  Lottery name to retrieve
     * @return lottery  The lottery configuration proper
     * @custom:revert  NotYetCreated
     */
    function get(string memory name) external view override returns (Config memory lottery) {
        lottery = _get(name);
    }

    /**
     * Create a new lottery with the given configuration
     *
     * @param name  Lottery name to use
     * @param config  Lottery configuration to use
     * @return success  True if creation was successful
     * @custom:revert  NameAlreadyInUse
     * @custom:revert  PlayersMustBeNonEmpty
     * @custom:revert  NumberOfWinnersMustBePositive
     * @custom:revert  NumberOfWinnersMustBeAtMostNumberOfPlayers
     */
    function create(string memory name, Config memory config) external override returns (bool success) {
        success = _create(name, config);
    }

    /**
     * Retrieve the list of winners
     *
     * @param name  Lottery name to retrieve winners for
     * @return prizeWinners  List of winners
     * @custom:revert  NotYetCreated
     */
    function winners(string memory name) external view override returns (string[] memory prizeWinners) {
        prizeWinners = _winners(_get(name));
    }

    /**
     * Simulate the execution of the given lottery configuration
     *
     * @param config  Lottery configuration to use
     * @return prizeWinners  List of winners
     * @custom:revert  PlayersMustBeNonEmpty
     * @custom:revert  NumberOfWinnersMustBePositive
     * @custom:revert  NumberOfWinnersMustBeAtMostNumberOfPlayers
     */
    function simulate(Config memory config) external pure override returns (string[] memory prizeWinners) {
        prizeWinners = _winners(_validate(config));
    }

    /**
     * Structure representing the internal state of the underlying RNG
     *
     * @custom:member state  The internal state (to be returned iteratively)
     * @custom:member index  The current bit position being returned
     * @custom:member round  The number of hash iterations done so far, incremented each time the state needs to be hashed
     */
    struct _Rng {
        bytes32 state;
        uint8 index;
        uint256 round;
    }

    /**
     * Validate the given lottery configuration
     *
     * @param config  Lottery configuration to validate
     * @return ok  The given configuration, if valid
     * @custom:revert  PlayersMustBeNonEmpty
     * @custom:revert  NumberOfWinnersMustBePositive
     * @custom:revert  NumberOfWinnersMustBeAtMostNumberOfPlayers
     */
    function _validate(Config memory config) internal pure returns (Config memory ok) {
        if (0 == config.players.length) {
            revert PlayersMustBeNonEmpty();
        }
        if (0 == config.numberOfWinners) {
            revert NumberOfWinnersMustBePositive();
        }
        if (config.players.length < config.numberOfWinners) {
            revert NumberOfWinnersMustBeAtMostNumberOfPlayers(config.players.length, config.numberOfWinners);
        }
        ok = config;
    }

    /**
     * Compute the hashed lottery name
     *
     * @param name  The lottery name to hash
     * @return nameHash  The hashed lottery name
     */
    function _nameHash(string memory name) internal pure returns (bytes32 nameHash) {
        nameHash = keccak256(bytes(name));
    }

    /**
     * Retrieve an existing lottery by name (internal)
     *
     * @param name  Lottery name to retrieve
     * @return lottery  The lottery configuration proper
     * @custom:revert  NotYetCreated
     */
    function _get(string memory name) internal view returns (Config memory lottery) {
        bytes32 nameHash = _nameHash(name);
        if (0 == _lotteries[nameHash].players.length) {
            revert NotYetCreated(name);
        }
        lottery = _lotteries[nameHash];
    }

    /**
     * Create a new lottery with the given configuration (internal)
     *
     * @param name  Lottery name to use
     * @param config  Lottery configuration to use
     * @return success  True if creation was successful
     * @custom:revert  NameAlreadyInUse
     * @custom:revert  PlayersMustBeNonEmpty
     * @custom:revert  NumberOfWinnersMustBePositive
     * @custom:revert  NumberOfWinnersMustBeAtMostNumberOfPlayers
     */
    function _create(string memory name, Config memory config) internal returns (bool success) {
        bytes32 nameHash = _nameHash(name);
        if (0 != _lotteries[nameHash].players.length) {
            revert NameAlreadyInUse(name);
        }
        _lotteries[nameHash] = _validate(config);
        return true;
    }

    /**
     * Retrieve the list of winners (internal)
     *
     * Winner retrieval entails creating a permutation of the first `config.players.length` numbers, and taking `config.numberOfWinners` many.
     * This ensures _uniform_ selection.
     *
     * In order to create the truncated permutation proper, the Fisher--Yates algorithm is run until `config.numberOfWinners` items have been
     * generated.
     * In order to feed the Fisher--yates algorithm, the FDR algorithm is used.
     * Finally, the result is sorted using MergeSort.
     *
     * WARNING: this method assumes the given configuration is indeed valid (as per _validateConfig(config)).
     *
     *
     * @param config  Lottery configuration to use
     * @return prizeWinners  List of winners
     */
    function _winners(Config memory config) internal pure returns (string[] memory prizeWinners) {
        uint256[] memory winnerIds = _mergeSort(_fisherYatesUpTo(_Rng(config.seed, 0, 0), config.players.length, config.numberOfWinners));
        prizeWinners = new string[](config.numberOfWinners);
        for (uint256 i = 0; i < config.numberOfWinners; i++) {
            prizeWinners[i] = config.players[winnerIds[i]];
        }
    }

    /**
     * Inside-out Fisher--Yates algorithm that only continues until the given number of members
     *
     * @custom:ref  "Fisher--Yates inside-out algorithm" https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle#The_%22inside-out%22_algorithm
     * @param rng  The RNG to use
     * @param size  The number of elements in total
     * @param until  The number of elements to generate
     * @return elements  The generated permutation
     */
    function _fisherYatesUpTo(_Rng memory rng, uint256 size, uint256 until) internal pure returns (uint256[] memory elements) {
        unchecked {
            uint256[] memory values = new uint256[](size);
            for (uint256 i = 0; i < size; i++) {
                values[i] = i;
            }
            elements = new uint256[](until);
            for (uint256 i = 0; i < until; i++) {
                uint256 j = i + _fdr(rng, size - i);
                (elements[i], values[j]) = (values[j], values[i]);
            }
        }
    }

    /**
     * Return a uniformly random integer between 0 (inclusive) and `max` (exclusive), using the given RNG
     *
     * This algorithm implements the FDR algorithm of Lumbroso.
     *
     * @custom:ref "Optimal Discrete Uniform Generation from Coin Flips, and Applications --- J\u00e9r\u00e9mie Lumbroso (2013)" https://arxiv.org/pdf/1304.1916
     * @param rng  The RNG to use
     * @param max  The maximum (exclusive) to generate
     * @return value  The generated number
     */
    function _fdr(_Rng memory rng, uint256 max) internal pure returns (uint256 value) {
        unchecked {
            uint256 limit = 1;
            while (true) {
                (limit, value) = (limit << 1, (value << 1) + _getBit(rng));
                if (max <= limit) {
                    if (value < max) {
                        break;
                    } else {
                        (limit, value) = (limit - max, value - max);
                    }
                }
            }
        }
    }

    /**
     * Retrieve a bit out of the given RNG
     *
     * @param rng  The RNG to use
     * @return bit  The extracted bit as a number
     */
    function _getBit(_Rng memory rng) internal pure returns (uint256 bit) {
        unchecked {
            if (0 == rng.index) {
                rng.state = keccak256(abi.encodePacked(rng.state, rng.round++));
            }
            bit = (0 != (uint8(rng.state[rng.index >> 3]) & (uint8(1) << (rng.index % 8)))) ? 1 : 0;
            rng.index++;
        }
    }

    /**
     * MergeSort implementation
     *
     * This method implements the MergeSort algorithm in a "Top-Down" straightforwards manner.
     * It makes sure to re-utilize the input as the output ao as to (somewhat) minimize copying.
     *
     *
     * @custom:ref "Merge Sort" https://en.wikipedia.org/wiki/Merge_sort
     * @param input  Input array to sort
     * @param output  Sorted array (actually a reference to the input array)
     */
    function _mergeSort(uint256[] memory input) internal pure returns (uint256[] memory output) {
        unchecked {
            uint256 length = input.length;
            if (2 <= length) {
                // set lengths and initialize, right length will always be AT LEAST equal to leftLength
                uint256 leftLength = length >> 1;
                uint256[] memory left = new uint256[](leftLength);
                uint256 rightLength = length - leftLength;
                uint256[] memory right = new uint256[](rightLength);
                // unordered split
                {
                    uint256 i;
                    uint256 j;
                    uint256 k;
                    // copy first half
                    while (j < leftLength) left[j++] = input[i++];
                    // copy second half
                    while (k < rightLength) right[k++] = input[i++];
                }
                // recursively call
                (left, right) = (_mergeSort(left), _mergeSort(right));
                // ordered merge
                {
                    uint256 i;
                    uint256 j;
                    uint256 k;
                    // merge by comparing heads
                    while (j < leftLength && k < rightLength) input[i++] = (left[j] <= right[k]) ? left[j++] : right[k++];
                    // deal with left slack
                    while (j < leftLength) input[i++] = left[j++];
                    // deal with right slack
                    while (k < rightLength) input[i++] = right[k++];
                }
            }
            output = input;
        }
    }
}
