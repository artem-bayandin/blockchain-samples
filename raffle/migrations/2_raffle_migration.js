const Raffle = artifacts.require('Raffle')
const ChainlinkDataFeeder = artifacts.require('ChainlinkDataFeeder')
const EthAggregatorMock = artifacts.require('EthAggregatorMock')
const LinkAggregatorMock = artifacts.require('LinkAggregatorMock')
const DaiAggregatorMock = artifacts.require('DaiAggregatorMock')
const BnbAggregatorMock = artifacts.require('BnbAggregatorMock')
const LinkMock = artifacts.require('LinkMock')
const DaiMock = artifacts.require('DaiMock')
const BnbMock = artifacts.require('BnbMock')
const LinkTokenMock = artifacts.require('LinkTokenMock')

const { erc20Mocks } = require('../common/deployment')

const setupTokenAndPriceOracle = async (mock, deployer, tokenContract, priceContract, overwriteOptions) => {
    // deploy 5 ERC20 token mocks, if not deployed
    await deployer.deploy(tokenContract, mock.name, mock.symbol, overwriteOptions)
    const erc20Token = await tokenContract.deployed()
    mock.tokenAddress = erc20Token.address
    // deploy proxies
    await deployer.deploy(priceContract, mock.decimals, overwriteOptions)
    const proxy = await priceContract.deployed()
    // connect proxies to tokens
    mock.proxyAddress = proxy.address
}

const setupProxy = async (mock, oracle) => {
    if (mock.isUsd) {
        await oracle.addTokenToUsd(mock.tokenAddress, mock.symbol, mock.proxyAddress, mock.decimals)
    } else {
        await oracle.addTokenToEth(mock.tokenAddress, mock.symbol, mock.proxyAddress, mock.decimals)
    }
}

module.exports = async function (deployer, network, accounts) {
    const overwriteOptions = {
        from: accounts[0],
        overwrite: true // false
    }

    if (network == 'devtest') {
        console.log('DEV_TEST network is chosen, overriding all the contracts')
        overwriteOptions.overwrite = true
    }

    if (network == 'development' || network == 'devtest') {
        console.log(`Deploying to '${network}' with overwriteOptions:`, overwriteOptions)

        // deploy Chainlinkdatafeeder, if not deployed
        await deployer.deploy(ChainlinkDataFeeder, overwriteOptions)
        const chainlinkPriceOracle = await ChainlinkDataFeeder.deployed()

        // deploy Linktokenmock
        await deployer.deploy(LinkTokenMock, overwriteOptions)
        const vrfLinkToken = await LinkTokenMock.deployed()

        // setup tokens and price oracles
        await setupTokenAndPriceOracle(erc20Mocks.link, deployer, LinkMock, LinkAggregatorMock, overwriteOptions)
        await setupTokenAndPriceOracle(erc20Mocks.dai, deployer, DaiMock, DaiAggregatorMock, overwriteOptions)
        await setupTokenAndPriceOracle(erc20Mocks.bnb, deployer, BnbMock, BnbAggregatorMock, overwriteOptions)
        // await Promise.all(erc20Mocks.map(async item => {
        //     // deploy 5 ERC20 token mocks, if not deployed
        //     await deployer.deploy(RaffleERC20TokenMock, item.name, item.symbol, overwriteOptions)
        //     const erc20Token = await RaffleERC20TokenMock.deployed()
        //     item.tokenAddress = erc20Token.address
        //     // deploy proxies
        //     await deployer.deploy(AggregatorV3Mock, item.initialProxyValue, item.decimals, overwriteOptions)
        //     const proxy = await AggregatorV3Mock.deployed()
        //     // connect proxies to tokens
        //     item.proxyAddress = proxy.address
        // }))

        // set up Chainlinkdatafeeder to point to currently deployed ERC20 mocks
        await deployer.deploy(EthAggregatorMock, 8, overwriteOptions)
        const ethProxy = await EthAggregatorMock.deployed()

        await chainlinkPriceOracle.setEthTokenProxy(ethProxy.address, await ethProxy.decimals());
        await setupProxy(erc20Mocks.link, chainlinkPriceOracle)
        await setupProxy(erc20Mocks.dai, chainlinkPriceOracle)
        await setupProxy(erc20Mocks.bnb, chainlinkPriceOracle)
        // await Promise.all(erc20Mocks.map(async item => {
        //     if (item.isUsd) {
        //         await chainlinkPriceOracle.addTokenToUsd(item.tokenAddress, item.symbol, item.proxyAddress, item.decimals)
        //     } else {
        //         await chainlinkPriceOracle.addTokenToEth(item.tokenAddress, item.symbol, item.proxyAddress, item.decimals)
        //     }
        // }))

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
            , '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B' // rinkeby address = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
            // , address _linkToken
            , vrfLinkToken.address // rinkeby link token = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
            // , bytes32 _randomnessKeyHash
            , '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311' // rinkeby hash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
            // , uint256 _randomnessFee
            , (1 * 10 ** 17).toString() // rinkeby fee = 0.1 LINK
            // , address _priceOracleAddress
            , chainlinkPriceOracle.address // local address of price oracle
        )
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
