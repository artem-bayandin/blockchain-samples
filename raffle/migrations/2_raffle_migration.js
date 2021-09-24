const Raffle = artifacts.require('Raffle')
const ChainlinkPriceOracle = artifacts.require('ChainlinkPriceOracle')
const ChainlinkRandomnessOracle = artifacts.require('ChainlinkRandomnessOracle') // this one won't be needed for local test deployment, i assume

// the next contracts are needed for tests
const EthAggregatorMock = artifacts.require('EthAggregatorMock')
const LinkAggregatorMock = artifacts.require('LinkAggregatorMock')
const DaiAggregatorMock = artifacts.require('DaiAggregatorMock')
const BnbAggregatorMock = artifacts.require('BnbAggregatorMock')
// some tokens for price proxies
const LinkMock = artifacts.require('LinkMock')
const DaiMock = artifacts.require('DaiMock')
const BnbMock = artifacts.require('BnbMock')

// randomness oracle mock
const RandomnessOracleMock = artifacts.require('RandomnessOracleMock')


const { deploymentSettings } = require('../common/deployment')

const setupTokenAndPriceOracle = async (mock, deployer, tokenContract, priceContract, overwriteOptions) => {
    // deploy 5 ERC20 token mocks, if not deployed
    await deployer.deploy(tokenContract, mock.name, mock.symbol, overwriteOptions)
    const erc20Token = await tokenContract.deployed()
    mock.tokenAddress = erc20Token.address
    // deploy proxies
    await deployer.deploy(priceContract, mock.decimals, mock.initialProxyValue, overwriteOptions)
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

        // deploy PriceOracle, if not deployed
        await deployer.deploy(ChainlinkPriceOracle, overwriteOptions)
        const chainlinkPriceOracle = await ChainlinkPriceOracle.deployed()
        // setup tokens and price oracles
        await setupTokenAndPriceOracle(deploymentSettings.link, deployer, LinkMock, LinkAggregatorMock, overwriteOptions)
        await setupTokenAndPriceOracle(deploymentSettings.dai, deployer, DaiMock, DaiAggregatorMock, overwriteOptions)
        await setupTokenAndPriceOracle(deploymentSettings.bnb, deployer, BnbMock, BnbAggregatorMock, overwriteOptions)
        // setup ETH price oracle
        await deployer.deploy(EthAggregatorMock, deploymentSettings.eth.decimals, deploymentSettings.eth.initialProxyValue, overwriteOptions)
        const ethProxy = await EthAggregatorMock.deployed()
        // setup proxies
        await chainlinkPriceOracle.setEthTokenProxy(ethProxy.address, await ethProxy.decimals());
        await setupProxy(deploymentSettings.link, chainlinkPriceOracle)
        await setupProxy(deploymentSettings.dai, chainlinkPriceOracle)
        await setupProxy(deploymentSettings.bnb, chainlinkPriceOracle)

        // deploy custom IRandomnessOracle
        await deployer.deploy(RandomnessOracleMock, overwriteOptions)
        const randomnessOracleMock = await RandomnessOracleMock.deployed()

        // deploy Raffle
        await deployer.deploy(
            Raffle
            // , uint256 _maxPlayers
            , 100
            // , uint256 _maxTokens
            , 100
            // , uint256 _ticketFee
            , (1 * 10 ** 9).toString() // 1,000,000,000 / 1,000,000,000,000,000,000
            // address _randomnessOracleAddress
            , randomnessOracleMock.address
            // address _priceOracleAddress
            , chainlinkPriceOracle.address // local address of price oracle
        )
        const raffle = await Raffle.deployed()

        console.log({
            owner: accounts[0],
            randomnessOracleAddress : randomnessOracleMock.address,
            priceOracleAddress: chainlinkPriceOracle.address,
            ethProxyAddress: ethProxy.address,
            raffleAddress: raffle.address,
            tokens: deploymentSettings
        })
    }

    // deployments to other networks
}
