// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { DevOpsTools } from "foundry-devops/src/DevOpsTools.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }

    function claimAirdrop(address airdropContractAddress) public {

        // Define parameters for the claim function
        address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Example address
        uint256 CLAIMING_AMOUNT = 2500 * 1e18; // Example: 2500 tokens with 18 decimals
        
        // Merkle proof will be defined next
        bytes32 PROOF_ONE = 0x9e10faf86d92c4c65f81ac54ef2a27cc0fdf6bfea6ba4b1df5955e47f187115b; // Example proof element
        bytes32 PROOF_TWO = 0x8c1fd7b608678f6dfced176fa3e3086954e8aa495613efcd312768d41338ceab; // Example proof element
        bytes32[] memory proof = new bytes32[](2); // Assuming a proof length of 2 for this example
        proof[0] = PROOF_ONE;
        proof[1] = PROOF_TWO;

        vm.startBroadcast(); // Prepare Foundry to send transactions

        // The actual call to MerkleAirdrop(airdropContractAddress).claim(...) will be added here

        vm.stopBroadcast(); // Submit the broadcasted transactions
    }
}