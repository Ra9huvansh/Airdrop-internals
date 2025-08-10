// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    event Claim(address indexed account, uint256 amount);

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;

    mapping(address claimant => bool) private s_hasClaimed;

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    //CEI Followed
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        // CHECK if already claimed
        if(s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // 1. Calculate the leaf node hash
        // This implementation double-hashes the abi.encoded data. 
        // Consistency between off-chain leaf generation and on-chain verification is paramount. 
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        // 2. Verify the Merkle Proof
        if(!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        s_hasClaimed[account] = true;
        
        // 3. Emit event
        emit Claim(account, amount);

        // 4. Transfer tokens
        i_airdropToken.safeTransfer(account, amount);
    }
}