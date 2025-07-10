// 1. 部署合约
const airdrop = await AntiWitchAirdrop.deploy(root, mockNFT, 1);

// 2. 注入 ETH
await web3.eth.sendTransaction({
  to: airdrop.address,
  from: accounts[0],
  value: web3.utils.toWei("1", "ether")
});

// 3. 调用 claim
await airdrop.claim(proof, 100);

// 4. 检查状态
const claimDataBefore = await airdrop.claims(accounts[0]);
console.log("Before withdraw:", claimDataBefore.lockedAmount.toNumber());

// 5. 推进时间并挖矿
await web3.currentProvider.send({
  jsonrpc: "2.0",
  method: "evm_increaseTime",
  params: [1],
  id: new Date().getTime()
});
await web3.currentProvider.send({
  jsonrpc: "2.0",
  method: "evm_mine",
  params: [],
  id: new Date().getTime()
});

// 6. 调用 withdraw
try {
  const tx = await airdrop.withdraw();
  console.log("Withdraw successful:", tx);
} catch (error) {
  console.error("Withdraw failed:", error.message);
}

// 7. 检查结果
const claimDataAfter = await airdrop.claims(accounts[0]);
console.log("After withdraw:", claimDataAfter.lockedAmount.toNumber());
