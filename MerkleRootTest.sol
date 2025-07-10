// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleRootTest {
    // 为用户列表生成Merkle根和特定用户的证明
    function generateMerkleData(address[] memory users, address targetUser) 
        public pure returns (bytes32 root, bytes32[] memory proof) 
    {
        require(users.length > 0, "At least one user required");
        
        // 计算所有叶节点哈希
        bytes32[] memory leaves = new bytes32[](users.length);
        uint targetIndex = type(uint).max;
        
        for (uint i = 0; i < users.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(users[i]));
            if (users[i] == targetUser) {
                targetIndex = i;
            }
        }
        
        require(targetIndex != type(uint).max, "Target user not found");
        
        // 构建Merkle树并生成证明
        root = buildMerkleTree(leaves);
        proof = generateProof(leaves, targetIndex);
    }
    
    // 构建Merkle树并返回根哈希
    function buildMerkleTree(bytes32[] memory leaves) internal pure returns (bytes32) {
        if (leaves.length == 0) return bytes32(0);
        if (leaves.length == 1) return leaves[0];
        
        bytes32[] memory currentLevel = leaves;
        
        while (currentLevel.length > 1) {
            bytes32[] memory nextLevel = new bytes32[]((currentLevel.length + 1) / 2);
            
            for (uint i = 0; i < currentLevel.length; i += 2) {
                bytes32 left = currentLevel[i];
                bytes32 right = i + 1 < currentLevel.length ? currentLevel[i + 1] : bytes32(0);
                nextLevel[i / 2] = keccak256(abi.encodePacked(left, right));
            }
            
            currentLevel = nextLevel;
        }
        
        return currentLevel[0];
    }
    
    // 生成特定索引的Merkle证明
    function generateProof(bytes32[] memory leaves, uint targetIndex) internal pure returns (bytes32[] memory) {
        bytes32[] memory proof = new bytes32[](log2ceil(leaves.length));
        uint proofIndex = 0;
        bytes32[] memory currentLevel = leaves;
        
        while (currentLevel.length > 1) {
            bool isLeft = targetIndex % 2 == 0;
            bytes32 sibling;
            
            if (isLeft) {
                if (targetIndex + 1 < currentLevel.length) {
                    sibling = currentLevel[targetIndex + 1];
                    proof[proofIndex] = sibling;
                    proofIndex++;
                }
            } else {
                sibling = currentLevel[targetIndex - 1];
                proof[proofIndex] = sibling;
                proofIndex++;
            }
            
            targetIndex = targetIndex / 2;
            bytes32[] memory nextLevel = new bytes32[]((currentLevel.length + 1) / 2);
            
            for (uint i = 0; i < currentLevel.length; i += 2) {
                bytes32 left = currentLevel[i];
                bytes32 right = i + 1 < currentLevel.length ? currentLevel[i + 1] : bytes32(0);
                nextLevel[i / 2] = keccak256(abi.encodePacked(left, right));
            }
            
            currentLevel = nextLevel;
        }
        
        // 调整数组大小为实际使用的长度
        bytes32[] memory finalProof = new bytes32[](proofIndex);
        for (uint i = 0; i < proofIndex; i++) {
            finalProof[i] = proof[i];
        }
        
        return finalProof;
    }
    
    // 计算向上取整的对数
    function log2ceil(uint256 x) internal pure returns (uint256) {
        uint256 result = 0;
        while ((1 << result) < x) {
            result++;
        }
        return result;
    }
    
    // 验证Merkle证明
    function verifyProof(bytes32[] memory proof, bytes32 root, address user) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, root, leaf);
    }
}    

