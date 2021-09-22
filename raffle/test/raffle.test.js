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

        console.log('ticketfee', ticketFee, 'max-allowance', MAX_ALLOWANCE)
    
        let raffle
        let raffleAddress
        let priceOracle
        let priceOracleAddress
        let randomnessOracle
        let randomnessOracleAddress

        const setupTokenAndProxy = async (mock, token, proxy) => {
            mock.token = await token.deployed()
            mock.proxy = await proxy.deployed()
            mock.tokenAddress = mock.token.address
            mock.proxyAddress = mock.proxy.address
        }

        const assignProxyToOracle = async (mock, oracle) => {
            if (mock.isUsd) {
                await oracle.addTokenToUsd(mock.tokenAddress, mock.symbol, mock.proxyAddress, mock.decimals)
            } else {
                await oracle.addTokenToEth(mock.tokenAddress, mock.symbol, mock.proxyAddress, mock.decimals)
            }
        }

        const mintToken = async (account, mock, owner) => {
            const tokensToMint = '1000'.padEnd('1000'.length + Number(await mock.token.decimals()), '0')
            console.log(`minting ${tokensToMint} of ${mock.symbol} to ${account}`)
            await mock.token.mint(account, tokensToMint.toString(), { from: owner })
        }

        const approveToken = async (mock, account, raffleAddress) => {
            const balance = await mock.token.balanceOf(account)
            const balanceTS = balance.toString()
            console.log(`approving ${balanceTS} from ${account} to ${raffleAddress}`)
            await mock.token.approve(raffleAddress, balanceTS, { from: account })
        }
        
        before(async () => {
            // deploy Chainlinkdatafeeder, if not deployed
            priceOracle = await ChainlinkPriceOracle.deployed()
            priceOracleAddress = priceOracle.address

            await setupTokenAndProxy(erc20Mocks.link, LinkMock, LinkAggregatorMock)
            await setupTokenAndProxy(erc20Mocks.dai, DaiMock, DaiAggregatorMock)
            await setupTokenAndProxy(erc20Mocks.bnb, BnbMock, BnbAggregatorMock)

            const ethProxy = await EthAggregatorMock.deployed()
            await priceOracle.setEthTokenProxy(ethProxy.address, await ethProxy.decimals());

            await assignProxyToOracle(erc20Mocks.link, priceOracle)
            await assignProxyToOracle(erc20Mocks.dai, priceOracle)
            await assignProxyToOracle(erc20Mocks.bnb, priceOracle)

            // mint 1000 of each token for each user
            await Promise.all(accounts.map(async account => {
                await mintToken(account, erc20Mocks.link, owner)
                await mintToken(account, erc20Mocks.dai, owner)
                await mintToken(account, erc20Mocks.bnb, owner)
            }))

            // setup randomness oracle
            randomnessOracle = await RandomnessOracleMock.deployed()
            randomnessOracleAddress = randomnessOracle.address

            console.log({
                priceOracleAddress,
                randomnessOracleAddress
            })
        })
        
        beforeEach(async () => {
            console.log('beforeEach entered')
            // deploy Raffle
            raffle = await Raffle.new(
                maxPlayers
                , maxTokens
                , ticketFee.toString() // 1,000,000,000 / 1,000,000,000,000,000,000
                , randomnessOracleAddress
                , priceOracleAddress
            )
            raffleAddress = raffle.address
            console.log(`raffle is created at address ${raffleAddress}`)
            // allow raffle to spend all tokens
            await Promise.all(accounts.map(async account => {
                await approveToken(erc20Mocks.link, account, raffle.address)
                await approveToken(erc20Mocks.dai, account, raffle.address)
                await approveToken(erc20Mocks.bnb, account, raffle.address)
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
