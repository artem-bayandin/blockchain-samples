const Raffle = artifacts.require('Raffle')
const ChainlinkDataFeeder = artifacts.require('ChainlinkDataFeeder')
const AggregatorV3Mock = artifacts.require('AggregatorV3Mock')
const RaffleERC20TokenMock = artifacts.require('RaffleERC20TokenMock')

const { erc20Mocks } = require('../common/deployment')

require('chai')
    .use(require('chai-bn')(web3.utils.BN))
    .use(require('chai-as-promised'))
    .should()

// as truffle runs migration and deploys all the contracts from there, 
// I cannot say how to get its addresses in here,
// as okay, for a single instance it might be MiContract.deployed() or so,
// but for contracts that are being publiched multiple times, then how to get its addresses?
contract('Raffle', async accounts => {
    try {
        const [ owner ] = accounts
        const maxPlayers = 100
        const maxTokens = 100
        const ticketFee = 1 * 10 ** 9
        const MAX_ALLOWANCE = 100 * 10 ** 18;
        
        const randomiserSettings = {
            vrfCoordinatorAddress: '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B',
            linkTokenAddress: '0x01BE23585060835E02B77ef475b0Cc51aA1e0709',
            randomnessKeyHash: '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311',
            randomnessFee: 1 * 10 ** 17 // 0.1 link
        }

        console.log('ticketfee', ticketFee, 'max-allowance', MAX_ALLOWANCE, 'randomnessFee', randomiserSettings.randomnessFee)
    
        let raffle
        let priceOracleAddress
        
        before(async () => {
            // deploy Chainlinkdatafeeder, if not deployed
            const chainlinkPriceOracle = await ChainlinkDataFeeder.new()
            priceOracleAddress = chainlinkPriceOracle.address
            await Promise.all(erc20Mocks.map(async mock => {
                // deploy 5 ERC20 token mocks, if not deployed
                const erc20Token = await RaffleERC20TokenMock.new(mock.name, mock.symbol)
                mock.tokenAddress = erc20Token.address
                mock.token = erc20Token
                // deploy proxies
                const proxy = await AggregatorV3Mock.new(mock.initialProxyValue, mock.decimals)
                // connect proxies to tokens
                mock.proxyAddress = proxy.address
                mock.proxy = proxy
            }))
            // set up Chainlinkdatafeeder to point to currently deployed ERC20 mocks
            const ethProxy = await AggregatorV3Mock.new(3800, 8)
            await chainlinkPriceOracle.setEthTokenProxy(ethProxy.address, await ethProxy.decimals());
            await Promise.all(erc20Mocks.map(async mock => {
                if (mock.isUsd) {
                    await chainlinkPriceOracle.addTokenToUsd(mock.tokenAddress, mock.symbol, mock.proxyAddress, mock.decimals)
                } else {
                    await chainlinkPriceOracle.addTokenToEth(mock.tokenAddress, mock.symbol, mock.proxyAddress, mock.decimals)
                }
            }))
            // mint 1000 of each token for each user
            await Promise.all(accounts.map(async account => {
                await Promise.all(erc20Mocks.map(async mock => {
                    // number of tokens is too big, so let's use string for that
                    const tokensToMint = '1000'.padEnd('1000'.length + Number(await mock.token.decimals()), '0')
                    console.log(`minting ${tokensToMint} of ${mock.symbol}`)
                    await mock.token.mint(account, tokensToMint.toString(), { from: owner })
                }))
            }))
        })
        
        beforeEach(async () => {
            console.log('beforeEach entered')
            // deploy Raffle
            raffle = await Raffle.new(
                maxPlayers
                , maxTokens
                , ticketFee.toString() // 1,000,000,000 / 1,000,000,000,000,000,000
                , randomiserSettings.vrfCoordinatorAddress
                , randomiserSettings.linkTokenAddress
                , randomiserSettings.randomnessKeyHash
                , randomiserSettings.randomnessFee.toString()
                , priceOracleAddress
            )
            console.log('raffle is created')
            // allow raffle to spend all tokens
            await Promise.all(accounts.map(async account => {
                await Promise.all(erc20Mocks.map(async mock => {
                    const balance = await mock.token.balanceOf(account)
                    const balanceTS = balance.toString()
                    console.log('approving', balanceTS)
                    await mock.token.approve(raffle.address, balanceTS, { from: account })
                }))
            }))
            console.log('tokens are approved')
        })
    
        describe('ititial', async () => {
            console.log('inside describe')
            it('should pass', async () => {
                assert(true, true)
                console.log('passed')
            })
        })
    } catch(err) {
        console.log('ERR!!', err)
    }
})