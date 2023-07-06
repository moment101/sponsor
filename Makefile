-include .env

build:; forge build

deploy-anvil:
	forge script script/Deploy.s.sol:OnAnvilScript --fork-url http://localhost:8545 --private-key $(ANVIL_USER0_PRIVATE_KEY) --broadcast -vvvv

deploy-sepolia:
	forge script script/Deploy.s.sol:OnSepoliaScript --rpc-url $(SEPOLIA_RPC_URL) --private-key $(TEST_ACCOUNT_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv