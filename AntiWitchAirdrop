// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AntiWitchAirdrop {
    bytes32 public merkleRoot;      // 合格用户Merkle根
    IERC721 public nftContract;    // NFT合约地址
    uint256 public unlockPeriod;   // 解锁周期（秒）
    address public admin;          // 管理员
    uint256 public totalAirdropped; // 已空投总额
    uint256 public totalWithdrawn;  // 已提取总额

    struct Claim {
        uint256 claimTime;     // 领取时间戳
        uint256 lockedAmount;  // 冻结空投金额
        uint256 lastWithdrawTime; // 上次提取时间
    }
    mapping(address => Claim) public claims;

    // 事件
    event AirdropClaimed(address indexed user, uint256 amount);
    event RewardWithdrawn(address indexed user, uint256 amount);
    event MerkleRootUpdated(bytes32 newRoot);

    // 修饰器：仅管理员
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    // 部署初始化
    constructor(bytes32 _merkleRoot, address _nft, uint256 _unlockPeriod) {
        merkleRoot = _merkleRoot;
        nftContract = IERC721(_nft);
        unlockPeriod = _unlockPeriod;
        admin = msg.sender;
    }

    // 更新Merkle根（补录用户）
    function updateMerkleRoot(bytes32 _newRoot) external onlyAdmin {
        merkleRoot = _newRoot;
        emit MerkleRootUpdated(_newRoot);
    }

    // 领取空投：校验Merkle + NFT持有 + 记录冻结
    function claim(bytes32[] calldata proof, uint256 amount) external {
        // 1. Merkle证明校验
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Proof");
        
        // 2. NFT持有校验
        require(nftContract.balanceOf(msg.sender) > 0, "No NFT");
        
        // 3. 防止重复领取
        require(claims[msg.sender].claimTime == 0, "Already claimed");
        
        // 4. 记录领取信息
        claims[msg.sender] = Claim({
            claimTime: block.timestamp,
            lockedAmount: amount,
            lastWithdrawTime: block.timestamp
        });
        
        totalAirdropped += amount;
        emit AirdropClaimed(msg.sender, amount);
    }

    // 提取解锁奖励：按时间比例释放
    function withdraw() external {
        Claim storage claimData = claims[msg.sender];
        require(claimData.claimTime > 0, "Not claimed");
        
        uint256 currentTime = block.timestamp;
        uint256 elapsed = currentTime - claimData.lastWithdrawTime;
        require(elapsed > 0, "No time elapsed");
        
        // 计算可释放比例（防止溢出）
        uint256 releaseRatio = elapsed * 100 / unlockPeriod;
        releaseRatio = releaseRatio > 100 ? 100 : releaseRatio;
        
        // 计算可释放金额
        uint256 releaseAmount = claimData.lockedAmount * releaseRatio / 100;
        require(releaseAmount > 0, "No unlockable amount");
        
        // 更新状态
        claimData.lockedAmount -= releaseAmount;
        claimData.lastWithdrawTime = currentTime;
        totalWithdrawn += releaseAmount;
        
        // 转账
        payable(msg.sender).transfer(releaseAmount);
        emit RewardWithdrawn(msg.sender, releaseAmount);
    }

    // 查看可提取金额
    function getWithdrawableAmount(address user) external view returns (uint256) {
        Claim memory claimData = claims[user];
        if (claimData.claimTime == 0) return 0;
        
        uint256 elapsed = block.timestamp - claimData.lastWithdrawTime;
        uint256 releaseRatio = elapsed * 100 / unlockPeriod;
        releaseRatio = releaseRatio > 100 ? 100 : releaseRatio;
        
        return claimData.lockedAmount * releaseRatio / 100;
    }

    // 合约余额查询
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}    
