const Raffle = artifacts.require('Raffle')
const ChainlinkDataFeeder = artifacts.require('ChainlinkDataFeeder')
const AggregatorV3Mock = artifacts.require('AggregatorV3Mock')
const RaffleERC20TokenMock = artifacts.require('RaffleERC20TokenMock')

// proxy addresses are taken from https://docs.chain.link/docs/ethereum-addresses/ for Rinkeby network.
// if deployed locally, proxy addresses should be updated to point to appropriate local AggregatorV3Mock
// tokens are named similar to its originals to have less confusion
// 'token' and 'tokenAddress' should be filled on deployment
// 'initialProxyValue' is used for locally deployed proxies to set some initial value to be returned
const erc20Mocks = [{
    name: 'LINK mock',
    symbol: 'LINKM',
    proxy: '0xd8bD0a1cB028a31AA859A21A3758685a95dE4623',
    decimals: 8,
    isUsd: true,
    tokenAddress: null,
    initialProxyValue: (25 * 10 ** 8).toString()
}, {
    name: 'DAI mock',
    symbol: 'DAIM',
    proxy: '0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D',
    decimals: 18,
    isUsd: false,
    tokenAddress: null,
    initialProxyValue: (1 * 10 ** 18).toString()
}, {
    name: 'BNB mock',
    symbol: 'BNBM',
    proxy: '0xcf0f51ca2cDAecb464eeE4227f5295F2384F84ED',
    decimals: 8,
    isUsd: true,
    tokenAddress: null,
    initialProxyValue: (367 * 10 ** 8).toString()
}, {
    name: 'TRX mock',
    symbol: 'TRXM',
    proxy: '0xb29f616a0d54FF292e997922fFf46012a63E2FAe',
    decimals: 8,
    isUsd: true,
    tokenAddress: null,
    initialProxyValue: (0.09 * 10 ** 8).toString()
}, {
    name: 'ZRX mock',
    symbol: 'ZRXM',
    proxy: '0xF7Bbe4D7d13d600127B6Aa132f1dCea301e9c8Fc',
    decimals: 8,
    isUsd: true,
    tokenAddress: null,
    initialProxyValue: (0.92 * 10 ** 8).toString()
}]

module.exports = async function (deployer, network, accounts) {
    const overwriteOptions = {
        from: accounts[0],
        overwrite: false
    }

    // deploy Chainlinkdatafeeder, if not deployed
    await deployer.deploy(ChainlinkDataFeeder, overwriteOptions)
    const chainlinkPriceOracle = await ChainlinkDataFeeder.deployed()

    if (network == 'development') {
        await Promise.all(erc20Mocks.map(async item => {
            // deploy 5 ERC20 token mocks, if not deployed
            await deployer.deploy(RaffleERC20TokenMock, item.name, item.symbol, overwriteOptions)
            const erc20Token = await RaffleERC20TokenMock.deployed()
            item.tokenAddress = erc20Token.address
            // deploy proxies
            await deployer.deploy(AggregatorV3Mock, item.initialProxyValue, item.decimals, overwriteOptions)
            const proxy = await AggregatorV3Mock.deployed()
            // connect proxies to tokens
            item.proxy = proxy.address
        }))
        // set up Chainlinkdatafeeder to point to currently deployed ERC20 mocks
        await deployer.deploy(AggregatorV3Mock, 3800, 8, overwriteOptions)
        const ethProxy = await AggregatorV3Mock.deployed()

        await chainlinkPriceOracle.setEthTokenProxy(ethProxy.address, await ethProxy.decimals());
        await Promise.all(erc20Mocks.map(async item => {
            if (item.isUsd) {
                await chainlinkPriceOracle.addTokenToUsd(item.tokenAddress, item.symbol, item.proxy, item.decimals)
            } else {
                await chainlinkPriceOracle.addTokenToEth(item.tokenAddress, item.symbol, item.proxy, item.decimals)
            }
        }))
        // deploy Raffle
        await deployer.deploy(
            Raffle
            // , uint256 _maxPlayers
            , 100
            // , uint256 _maxTokens
            , 100
            // , uint256 _ticketFee
            , (1 * 10 ** 9).toString() // 1,000,000,000 / 1,000,000,000,000,000,000
            // , address _vrfCoordinator
            , '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B' // rinkeby address
            // , address _linkToken
            , '0x01BE23585060835E02B77ef475b0Cc51aA1e0709' // rinkeby link token
            // , bytes32 _randomnessKeyHash
            , '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311' // rinkeby hash
            // , uint256 _randomnessFee
            , (1 * 10 ** 17).toString() // rinkeby fee = 0.1 LINK
            // , address _priceOracleAddress
            , chainlinkPriceOracle.address // local address of price oracle
        );
        const raffle = await Raffle.deployed()

        console.log({
            owner: accounts[0],
            chainlinkPriceOracleAddress: chainlinkPriceOracle.address,
            ethProxyAddress: ethProxy.address,
            raffleAddress: raffle.address,
            tokens: erc20Mocks
        })
    }

    /*
            The below code should be updated according to what is there above.
    */

    /*
    if (network == 'rinkeby') {
        // deploy 5 ERC20 token mocks, if not deployed
        await Promise.all(erc20Mocks.map(async item => {
            item.token = await deployer.deploy(RaffleERC20TokenMock, item.name, item.symbol, overwriteOptions)
            item.tokenAddress = token.address
        }))
        // set up Chainlinkdatafeeder to point to currently deployed ERC20 mocks
        await chainlinkPriceOracle.setEthTokenProxy(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e, 8);
        await Promise.all(erc20Mocks.map(async item => {
            if (item.isUsd) {
                await chainlinkPriceOracle.addTokenToUsd(item.tokenAddress, item.symbol, item.proxy, item.decimals)
            } else {
                await chainlinkPriceOracle.addTokenToEth(item.tokenAddress, item.symbol, item.proxy, item.decimals)
            }
        }))
        // deploy Raffle
        const raffle = await deployer.deploy(
            Raffle
            // , uint256 _maxPlayers
            , 100
            // , uint256 _maxTokens
            , 100
            // , uint256 _ticketFee
            , 1 * 10 ** 9 // 1,000,000,000 / 1,000,000,000,000,000,000
            // , address _vrfCoordinator
            , '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B' // rinkeby address from https://docs.chain.link/docs/vrf-contracts/
            // , address _linkToken
            , '0x01BE23585060835E02B77ef475b0Cc51aA1e0709' // rinkeby link token from https://docs.chain.link/docs/vrf-contracts/
            // , bytes32 _randomnessKeyHash
            , '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311' // rinkeby hash from https://docs.chain.link/docs/vrf-contracts/
            // , uint256 _randomnessFee
            , 1 * 10 ** 17 // rinkeby fee = 0.1 LINK from https://docs.chain.link/docs/vrf-contracts/
            // , address _priceOracleAddress
            , chainlinkPriceOracle.address // local address of price oracle
        );

        console.log({
            owner: accounts[0],
            chainlinkPriceOracleAddress: chainlinkPriceOracle.address,
            raffleAddress: raffle.address,
            tokens: erc20Mocks
        })
    }
    */
}
