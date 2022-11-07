// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

/**
 * Blockchain-based Lottery
 *
 * This interface allows you to interact with a blockchain-based lottery able to deal several prizes to a given population.
 * All the inputs needed to reproduce the result are persisted in the blockchain, so as to be auditable and reproducible.
 *
 *
 * The Lottery works like so:
 *   - a new Lottery must be created, in order to do so, you need a name for it, the seed to use, the participant population
 *     as a list of strings, and the number of prizes that will be dealt
 *   - once the lottery is created, exists(name) will return true, and get(name) will return a structure representing the seed to
 *     use, the population, and the number of prizes
 *   - finally, with a created lottery, calling winners(name) will return the prize winners in no particular order.
 *   - alternatively, the simulate(config) method can be called to obtain the winners without persisting anything on the
 *     blockchain.
 *
 * Let's follow along a simple example.
 * We want to create a Lottery that will deal 5 prizes amongst 100 participants, using a zero seed, we'll call it "Doing the
 * dishes for 100 dudes".
 *
 * We first need to call (we'll use ">>>" to denote calls, and "<<<" responses):
 *
 *   >>> create("Doing the dishes for 100 dudes", ["0x00...0", 5, ["one", "two", ..., "one hundred"]])
 *   <<< bool: success true
 *
 * Now we can check whether it was indeed created by doing:
 *
 *   >>> exists("Doing the dishes for 100 dudes")
 *   <<< bool: existing true
 *
 * and retrieve the Lottery's parameters by:
 *
 *   >>> get("Doing the dishes for 100 dudes")
 *   <<< tuple(bytes32,uint256,string[]): lottery 0x00...0,5,["one","two",...,"one hundred"]
 *
 * (see how this is the same data the create() call returns).
 * Finally, we can retrieve the unlucky winners by calling:
 *
 *   >>> winners("Doing the dishes for 100 dudes")
 *   <<< string[]: winners "nineteen","twenty-three","sixty-six","ninety-two","ninety-nine"
 *
 * this means that participants 19, 23, 66, 92, and 99 won the coveted responsibility of doing the dishes.
 *
 *
 * Notice that once the Lottery is created, the winners are all implicitly determined automatically, and persisted in the blockchain
 * for all to see and audit.
 */
interface ILottery {

    /**
     * Raised upon encountering a non-existing lottery name
     *
     * @param name  The offending name
     */
    error NotYetCreated(string name);

    /**
     * Raised upon encountering an already-existing lottery name
     *
     * @param name  The offending name
     */
    error NameAlreadyInUse(string name);

    /**
     * Raised upon encountering an empty players list
     *
     */
    error PlayersMustBeNonEmpty();

    /**
     * Raised upon encountering a 0-size selection (ie. the number of winners)
     *
     */
    error NumberOfWinnersMustBePositive();

    /**
     * Raised upon encountering a number of winners greater than the corresponding population
     *
     * @param numberOfPlayers  The offending number of players
     * @param numberOfWinners  The offending number of winners
     */
    error NumberOfWinnersMustBeAtMostNumberOfPlayers(uint256 numberOfPlayers, uint256 numberOfWinners);

    /**
     * Structure representing a lottery configuration
     *
     * @custom:member seed  The RNG seed to use for this lottery
     * @custom:member numberOfWinners  The number of winners to use for this lottery
     * @custom:member players  A list of players for this lottery (this list CAN contain duplicates to simulate non-uniform odds)
     */
    struct Config {
        bytes32 seed;
        uint256 numberOfWinners;
        string[] players;
    }

    /**
     * Determine whether the given lottery name exists
     *
     * @param name  Lottery name to check
     * @return existing  True if the given lottery name exists, false otherwise
     */
    function exists(string memory name) external view returns (bool existing);

    /**
     * Retrieve an existing lottery by name
     *
     * @param name  Lottery name to retrieve
     * @return lottery  The lottery configuration proper
     * @custom:revert  NotYetCreated
     */
    function get(string memory name) external view returns (Config memory lottery);

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
    function create(string memory name, Config memory config) external returns (bool success);

    /**
     * Retrieve the list of winners
     *
     * @param name  Lottery name to retrieve winners for
     * @return prizeWinners  List of winners
     * @custom:revert  NotYetCreated
     */
    function winners(string memory name) external view returns (string[] memory prizeWinners);

    /**
     * Simulate the execution of the given lottery configuration
     *
     * @param config  Lottery configuration to use
     * @return prizeWinners  List of winners
     * @custom:revert  PlayersMustBeNonEmpty
     * @custom:revert  NumberOfWinnersMustBePositive
     * @custom:revert  NumberOfWinnersMustBeAtMostNumberOfPlayers
     */
    function simulate(Config memory config) external pure returns (string[] memory prizeWinners);
}
