// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { DevOpsTools } from "foundry-devops/src/DevOpsTools.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {

    error ClaimAirdrop__InvalidSignatureLength();

    // Define parameters for the claim function
    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Example address
    uint256 CLAIMING_AMOUNT = 2500 * 1e18; // Example: 2500 tokens with 18 decimals

    // Merkle proof will be defined next
    bytes32 PROOF_ONE = 0x9e10faf86d92c4c65f81ac54ef2a27cc0fdf6bfea6ba4b1df5955e47f187115b;
    bytes32 PROOF_TWO = 0x8c1fd7b608678f6dfced176fa3e3086954e8aa495613efcd312768d41338ceab;
    bytes32[] private proof = [PROOF_ONE, PROOF_TWO]; // Assuming a proof length of 2

    bytes private SIGNATURE = hex"3e2a646cc154217a8dbaf38064102a1199264ea7883f13d754c8b8ea7d502421576aadfc3d9c3b2aaa44b61f53a35a1f57e32bb4f2628789cbdd95a96a60fd5e1b";

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }

    function claimAirdrop(address airdropContractAddress) public {

        vm.startBroadcast(); // Prepare Foundry to send transactions

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        console.log("Claiming Airdrop");

        MerkleAirdrop(airdropContractAddress).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, proof, v, r, s);

        vm.stopBroadcast(); // Submit the broadcasted transactions
        console.log("Claimed Airdrop");

    }

    /**
     * @notice Splits a 65-byte concatenated signauture (r,s,v) into its components.
     * @param sig The concatenated signature as bytes.
     * @return v The recovery identifier (1 byte).
     * @return r The r value of the signature (32 bytes).
     * @return s The s value of the signature (32 bytes).
     */

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        // Standard ECDSA signatures are 65 bytes long:
        // r (32 bytes) + s (32 bytes) + v (1 byte)
        if (sig.length != 65) {
            revert ClaimAirdrop__InvalidSignatureLength();
        }
        // Accessing bytes data in assembly requires careful memory management.
        // `sig` in assembly points to the length of the byte array.
        // The actual data starts 32 bytes after this pointer.
        assembly {
            // Load the first 32 bytes (r)
            r := mload(add(sig, 32))
            // Load the next 32 bytes (s)
            s := mload(add(sig, 64))
            // Load the last byte (v)
            // v is the first byte of the 32-byte word starting at offset 96 (0x60)
            v := byte(0, mload(add(sig, 96)))
            // if (v < 27) {
            //     v = v + 27;
            // }
        }
    }
}