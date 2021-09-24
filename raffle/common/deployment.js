// proxy addresses are taken from https://docs.chain.link/docs/ethereum-addresses/ for Rinkeby network.
// if deployed locally, proxy addresses should be updated to point to appropriate local AggregatorV3Mock
// tokens are named similar to its originals to have less confusion
// 'token' and 'tokenAddress' should be filled on deployment
// 'initialProxyValue' is used for locally deployed proxies to set some initial value to be returned
const deploymentSettings = {
    eth: {
        decimals: 8,
        initialProxyValue: (3800 * 10 ** 8).toString()
    },
    link: {
        name: 'LINK mock',
        symbol: 'LINKM',
        proxyAddress: '0xd8bD0a1cB028a31AA859A21A3758685a95dE4623',
        decimals: 8,
        isUsd: true,
        tokenAddress: null,
        initialProxyValue: (25 * 10 ** 8).toString()
    },
    dai: {
        name: 'DAI mock',
        symbol: 'DAIM',
        proxyAddress: '0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D',
        decimals: 18,
        isUsd: false,
        tokenAddress: null,
        initialProxyValue: (1 * 10 ** 18).toString()
    },
    bnb: {
        name: 'BNB mock',
        symbol: 'BNBM',
        proxyAddress: '0xcf0f51ca2cDAecb464eeE4227f5295F2384F84ED',
        decimals: 8,
        isUsd: true,
        tokenAddress: null,
        initialProxyValue: (367 * 10 ** 8).toString()
    }
}
/*
[, , , {
    name: 'TRX mock',
    symbol: 'TRXM',
    proxyAddress: '0xb29f616a0d54FF292e997922fFf46012a63E2FAe',
    decimals: 8,
    isUsd: true,
    tokenAddress: null,
    initialProxyValue: (0.09 * 10 ** 8).toString()
}, {
    name: 'ZRX mock',
    symbol: 'ZRXM',
    proxyAddress: '0xF7Bbe4D7d13d600127B6Aa132f1dCea301e9c8Fc',
    decimals: 8,
    isUsd: true,
    tokenAddress: null,
    initialProxyValue: (0.92 * 10 ** 8).toString()
}]
*/

module.exports = {
    deploymentSettings
}