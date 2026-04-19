// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    event Claim(address account, uint256 amount);

    // some list of address
    // Allow someone in the list to claim token
    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool claimed) s_hasClaimed;

    // merkle proofs
    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    // follow CEI
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        // calculate using the account and the amount, the hash -> leaf node
        // to avoid collision, we hash them twice
        
        if(s_hasClaimed[account]){
            revert MerkleAirdrop__AlreadyClaimed();
        }
        
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if(!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)){
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        // if we not able to send the tokens by any reason, it will handle it
        i_airdropToken.safeTransfer(account, amount);
    }

    function getMerkleRoot() external view returns(bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

}