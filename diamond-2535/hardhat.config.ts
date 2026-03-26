import hardhatToolboxMochaEthersPlugin from '@nomicfoundation/hardhat-toolbox-mocha-ethers'
import { defineConfig, HardhatUserConfig } from 'hardhat/config'
import hardhatContractSizer from '@solidstate/hardhat-contract-sizer'

const PK = '0x1000000000000000000000000000000000000000000000000000000000000001'

const config: HardhatUserConfig = {
  plugins: [
    hardhatToolboxMochaEthersPlugin,
    hardhatContractSizer,
  ],
  // https://hardhat.org/docs/reference/configuration#path-configuration
  solidity: {
    version: "0.8.33",
    settings: {
      evmVersion: 'osaka',
      optimizer: {
        enabled: true,
        runs: 1331,
      },
    },
  },
  // solidity: {
  //   profiles: {
  //     default: {
  //       version: "0.8.33",
  //       settings: {
  //         evmVersion: 'osaka',
  //         optimizer: {
  //           enabled: true,
  //           runs: 1331,
  //         },
  //       },
  //     },
  //     production: {
  //       version: "0.8.33",
  //       settings: {
  //         evmVersion: 'osaka',
  //         optimizer: {
  //           enabled: true,
  //           runs: 1331,
  //         },
  //       },
  //     },
  //   },
  // },
  networks: {
    // https://github.com/NomicFoundation/hardhat/discussions/7257#discussioncomment-2149626
    default: {
      type: "edr-simulated",
      chainType: "l1",
      chainId: 127002,
      accounts: [
        { privateKey: '0x1000000000000000000000000000000000000000000000000000000000000001', balance: '40200000000000000000000' },
        { privateKey: '0x1000000000000000000000000000000000000000000000000000000000000002', balance: '40200000000000000000000' },
        { privateKey: '0x1000000000000000000000000000000000000000000000000000000000000003', balance: '40200000000000000000000' },
        { privateKey: '0x1000000000000000000000000000000000000000000000000000000000000004', balance: '40200000000000000000000' },
        { privateKey: '0x1000000000000000000000000000000000000000000000000000000000000005', balance: '40200000000000000000000' },
        { privateKey: '0x1000000000000000000000000000000000000000000000000000000000000006', balance: '40200000000000000000000' },
        { privateKey: '0x1000000000000000000000000000000000000000000000000000000000000007', balance: '40200000000000000000000' },
        { privateKey: '0x1000000000000000000000000000000000000000000000000000000000000008', balance: '40200000000000000000000' },
        { privateKey: '0x1000000000000000000000000000000000000000000000000000000000000009', balance: '40200000000000000000000' },
        { privateKey: '0x1000000000000000000000000000000000000000000000000000000000000010', balance: '40200000000000000000000' }
      ],
      // mining: {
      //   auto: false,
      //   interval: 5000, // 1 sec
      // }
    },
    localhost: {
      type: "http",
      chainType: "l1",
      url: "http://127.0.0.1:8545",
    },
    // https://hardhat.org/docs/reference/configuration#simulated-network-options
    // https://hardhat.org/docs/reference/configuration#shared-network-options
    amoy: {
      type: "http",
      chainType: "l1",
      chainId: 80002,
      url: "https://rpc-amoy.polygon.technology",
      accounts: [PK],
    },
    polygon: {
      type: "http",
      chainType: "l1",
      chainId: 137,
      url: "https://polygon-rpc.com",
      accounts: [PK],
    },
    ethereum: {
      type: "http",
      chainType: "l1",
      chainId: 1,
      url: "https://ethereum-rpc.publicnode.com",
      accounts: [PK],
    },
  },
  // https://hardhat.org/docs/reference/configuration#path-configuration
  paths: {
    sources: './contracts',
    artifacts: './compiled/artifacts',
    cache: './compiled/cache',
    ignition: './ignition',
    tests: './test',
  },
  // https://hardhat.org/docs/reference/configuration#typechain-configuration
  typechain: {
    outDir: "./compiled/types",
  },
  contractSizer: {
    alphaSort: false,
    runOnCompile: false,
    flat: false,
    strict: false,
    only: [],
    except: [],
    unit: 'KiB'
  },
}

export default defineConfig(config)
