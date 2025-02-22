include .env

private_key?=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
local_port?=8545
chain_id?=17001

local_rpc_url := http://127.0.0.1:$(local_port)

deploy-to-base-sepolia:
	forge script script/DeployLottery.s.sol --rpc-url $(BASE_SEPOLIA_RPC_URL) --private-key $(METAMASK_PRIVATE_KEY) --broadcast

.PHONY: deploy-local-anvil
deploy-local-anvil:
	forge script script/DeployLottery.s.sol --rpc-url $(local_rpc_url) --broadcast --private-key $(private_key)

.PHONY: start-anvil
start-anvil:
	anvil -a 30 -p $(local_port) --chain-id $(chain_id) --block-time 10
