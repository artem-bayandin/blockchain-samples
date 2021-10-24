module.exports = {
    networks: {
        development: {
            host: "127.0.0.1", // Localhost (default: none)
            port: 7545, // Standard Ethereum port (default: none)
            network_id: "*", // Any network (default: none)
        },
    },

    contracts_build_directory: "./src/contracts",
    compilers: {
        solc: {
            version: "0.8.7", // Fetch exact version from solc-bin (default: truffle's version)
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200,
                }
            },
        },
    }
};
