-include .env

build:; forge build

deploy-sepolia:; forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast