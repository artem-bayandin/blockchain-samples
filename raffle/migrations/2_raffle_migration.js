const Raffle = artifacts.require('Raffle')
const ChainlinkDataFeeder = artifacts.require('ChainlinkDataFeeder')
const AggregatorV3Mock = artifacts.require('AggregatorV3Mock')
const RaffleERC20TokenMock = artifacts.require('RaffleERC20TokenMock')

import { erc20Mocks } from '../common/deployment'

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
