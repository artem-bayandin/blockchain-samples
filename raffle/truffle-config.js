const HDWalletProvider = require('@truffle/hdwallet-provider');

const fs = require('fs');

const readFile = (fPath) => {
    if (fs.existsSync(fPath)) {
        return fs.readFileSync(fPath).toString().trim();
    }
}

const rinkeby = {
    mnemonic: readFile('./deployment/rinkeby/.mnemonic.secret'),
    from: readFile('./deployment/rinkeby/.from-address.secret'),
    infuraProjectId: readFile('./deployment/rinkeby/.infura-project-id.secret')
}

const rinkebyNetworkSettings = {
    provider: function () {
        // return new HDWalletProvider(rinkebySecret, `https://rinkeby.infura.io/v3/${rinkebyInfuraProjectId}`)
        return new HDWalletProvider(rinkeby.mnemonic, `wss://rinkeby.infura.io/ws/v3/${rinkeby.infuraProjectId}`)
    },
    network_id: 4, // Rinkeby's id
    gas: 4000000, // Ropsten has a lower block limit than mainnet
    gasPrice: 20000000000,
    confirmations: 0, // # of confs to wait between deployments. (default: 0)
    skipDryRun: false, // Skip dry run before migrations? (default: false for public nets )
    websocket: true,
    timeoutBlocks: 50000, // # of blocks before a deployment times out  (minimum/default: 50)
    networkCheckTimeout: 90000,
    from: rinkeby.from
}

const localhostNetworkSettings = {
    host: "127.0.0.1", // Localhost (default: none)
    port: 7545, // Standard Ethereum port (default: none)
    network_id: 5777, // Any network (default: none)
    gas: 10000000,
}

module.exports = {
    networks: {
        development: localhostNetworkSettings,
        devtest: localhostNetworkSettings,
        rinkeby: rinkebyNetworkSettings,
    },

    // Set default mocha options here, use special reporters etc.
    mocha: {
        // timeout: 100000
    },

    contracts_build_directory: "./src/contracts",
    // Configure your compilers
    compilers: {
        solc: {
            version: "0.8.7", // Fetch exact version from solc-bin (default: truffle's version)
            // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
            settings: {
                // See the solidity docs for advice about optimization and evmVersion
                optimizer: {
                    enabled: true,
                    runs: 200,
                },
                //    evmVersion: "byzantium"
            },
        },
    }
};
