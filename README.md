# Qrate Hardhat Project

This project demonstrates the Qrate contract use case.

To get started, run

```shell
git glone https://github.com/qrate97/contracts
npm install
```

Create a .env file according to the .env.example specified, add your wallet's private key and make sure it has funds to deploy the contract

```shell
npx hardhat compile
npx hardhat run scripts/deploy.js --network mumbai
```

Copy the address of the deployed contract (will be needing on in the subgraph)

The contract's ABI can be found in the artifacts/contracts/Qrate.sol/Qrate.json
