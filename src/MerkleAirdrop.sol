// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712{
    using SafeERC20 for IERC20;

    // EIP-712 Typehash for our specific claim structure
    // "AirdropClaim(address account,uint256 amount)"
    bytes32 private constant MESSAGE_TYPEHASH = 0x810786b83997ad50983567660c1d9050f79500bb7c2470579e75690d45184163;
    // It's good practice to pre-compute this hash: keccak256("AirdropClaim(address account,uint256 amount)")

    // The struct representing the data to be signed
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    error MerkleAirdrop__InvalidSignature();
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    event Claim(address indexed account, uint256 amount);

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;

    mapping(address claimant => bool) private s_hasClaimed;

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    // Function to compute the EIP-712 digest
    function getMessageDigest(address account, uint256 amount) public view returns (bytes32) {
        // 1. Hash the struct instance according to EIP-712 struct hashing rules
        bytes32 structHash = keccak256(abi.encode(
            MESSAGE_TYPEHASH,
            AirdropClaim({
                account: account,
                amount: amount
            })
        ));

        // 2. Combine with domain separator using _hasTypedDataV4 from EIP712 contract
        // _hasTypedDataV4 constructs the EIP-712 digest:
        // keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash))
        return _hashTypedDataV4(structHash);
    }

    // Add this internal function to your contract 
    function _isValidSignature(
        address expectedSigner, // The address we expect to have signed (claim.account)
        bytes32 digest, // The EIP-712 digest calculated by getMessageDigest
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        // Attempt to recover the signer address from the digest and signature components
        // ECDSA.tryRecover is preferred as it handles signature malleability and 
        // returns address(0) on failure instead of reverting.
        bytes memory signature = abi.encode(v, r, s);
        (address actualSigner,,) = ECDSA.tryRecover(digest, signature);

        // Check two things:
        // 1. Recovery was successful (actualSigner is not the zero address).
        // 2. The recovered address matches the expected signer (the 'account' parameter).
        return actualSigner != address(0) && actualSigner == expectedSigner;
    }

    //CEI Followed
    function claim (
        address account, // The recipient/signer address
        uint256 amount, // The amount being claimed
        bytes32[] calldata merkleProof, // Merkle proof for the claim
        uint8 v, // Signature recovery ID
        bytes32 r, // Signature component r
        bytes32 s // Signature component s
    ) external {
        // CHECK if already claimed
        if(s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // --- New Signature Verification ---
        // Construct the digest the user should have signed
        bytes32 digest = getMessageDigest(account, amount);
        //Verify the signature
        if(!_isValidSignature(account, digest, v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        // --- End of Signature Check ---

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

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}