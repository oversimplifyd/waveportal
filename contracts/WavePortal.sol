// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract WavePortal is VRFConsumerBase {
    uint256 totalWaves;
    uint256 private seed;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    event NewWave(address indexed from, uint256 timestamp, string message);

    struct Wave {
        address waver;
        string message;
        uint256 timestamp;
    }

    Wave[] waves;

    /*
     * This is an address => uint mapping, meaning I can associate an address with a number!
     * In this case, I'll be storing the address with the last time the user waved at us.
     */
    mapping(address => uint256) public lastWavedAt;

    constructor() 
        VRFConsumerBase(
            0x6168499c0cFfCaCD319c818142124B7A15E857ab, // VRF Coordinator -> Rinkeby Testnet 
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token -> Rinkeby  Testnet
        ) payable {
        
        keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    function wave(string memory _message) external {
        /*
         * We need to make sure the current timestamp is at least 15-minutes bigger than the last timestamp we stored
         */
        require(
            lastWavedAt[msg.sender] + 15 minutes < block.timestamp,
            "Wait 15m"
        );

        /*
         * Update the current timestamp we have for the user
         */
        lastWavedAt[msg.sender] = block.timestamp;

        totalWaves += 1;

        waves.push(Wave(msg.sender, _message, block.timestamp));

        /*
         * Generate a new seed for the next user that sends a wave
         */
        seed = uint256(getRandomNumber()) % uint256(100);

        if (seed <= 50) {
            uint256 prizeAmount = 0.0001 ether;
            require(
                prizeAmount <= address(this).balance,
                "Trying to withdraw more money than they contract has."
            );

            (bool success, ) = (msg.sender).call{value: prizeAmount}("");
            require(success, "Failed to withdraw money from contract.");
        }
        
        emit NewWave(msg.sender, block.timestamp, _message);
    }

    function getAllWaves() external view returns (Wave[] memory) {
        return waves;
    }

    function getTotalWaves() external view returns (uint256) {
        return totalWaves;
    }

    /** 
    * Requests randomness from a user-provided seed
    */
    function getRandomNumber() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
    * Callback function used by VRF Coordinator
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
}