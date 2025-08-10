// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";
import { BagelToken } from "../src/BagelToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public airdrop;
    BagelToken public token;

    bytes32 public ROOT = 0xa4d8c8776abd94bb36f381cff5af341303a00299fe70e1c3ba365f7004c4d0b2;
    uint256 public AMOUNT_TO_CLAIM = 2500 * 1e18; //Example claim amount for the test user
    uint256 public AMOUNT_TO_SEND; // Total tokens to fund the airdrop contract

    //User-specific data
    address user;
    uint256 userPrivKey; //Private key for the test user

    // Merkle Proof for the test user
    // The structure (e.g., bytes[2]) depends on your Merkle tree's depth
    // These specific values will be populated from your Merkle tree ouput
    bytes32 proofOne = 0x9e10faf86d92c4c65f81ac54ef2a27cc0fdf6bfea6ba4b1df5955e47f187115b;
    bytes32 proofTwo = 0x8c1fd7b608678f6dfced176fa3e3086954e8aa495613efcd312768d41338ceab;
    bytes32[] public PROOF = [proofOne, proofTwo];

    function setUp() public {
        // 1. Deploy the ERC20 Token 
        token = new BagelToken();

        // 2. Generate a Deterministic Test User
        // `makeAddrAndKey` creates a predictable address and private key.
        // This is crucial because we need to know the user's address *before*
        // generating the Merkle tree that includes them.
        (user, userPrivKey) = makeAddrAndKey("testUser");
        console.log(user);

        // 3. Deploy the MerkleAirdrop contract
        // Pass the Merkle ROOT and the address of the token contract
        airdrop = new MerkleAirdrop(ROOT, IERC20(address(token)));

        // 4. Fund the Airdrop contract (Critical Step!)
        // The airdrop contract needs tokens to distribute.
        // Let's assume our test airdrop is for 4 users, each claiming AMOUNT_TO_CLAIM,
        AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;

        // The test contract itself is the owner of the BagelToken by default upon deployment
        address owner = address(this);

        // Mint tokens to the owner (the test contract).
        token.mint(owner, AMOUNT_TO_SEND);

        // Transfer the minted tokens to the airdrop contract.
        // Note the explicit cast of `airdrop` (contract instance) to `address`. 
        token.transfer(address(airdrop), AMOUNT_TO_SEND);
    }

    function testUsersCanClaim() public {
        // 1. Get the user's starting token balance
        uint256 startingBalance = token.balanceOf(user);
        console.log(startingBalance);

        // 2. Simulate the claim transaction from the user's address
        // `vm.prank(address)` sets `address` for the *next* external call only
        vm.prank(user);

        // 3. Call the claim function on the airdrop contract
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF);

        // 4. Get the user's ending token balance
        uint256 endingBalance = token.balanceOf(user);

        // For debugging, you can log the ending balance
        console.log("User's Ending Balance: ", endingBalance);

        // 5. Assert that the balance increased by the expected claim amount
        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM, "User did not receive the correct amount of tokens");
    }
}