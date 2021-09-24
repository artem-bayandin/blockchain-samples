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

const { assert, expect } = require('chai')
const BN = require('bn.js')
const { deploymentSettings } = require('../common/deployment')

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
        // cut the number of accounts to 5
        accounts = accounts.slice(0, 5)
        const [ owner ] = accounts
        const maxPlayers = 100
        const maxTokens = 100
        const ticketFee = 1 * 10 ** 9
        const MAX_ALLOWANCE = 100 * 10 ** 18;
        const tokensToMint = 1000 * 10 ** 8

        console.log('ticketfee', ticketFee, 'max-allowance', MAX_ALLOWANCE, 'tokensToMint', tokensToMint)
    
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
            await mock.token.mint(account, tokensToMint.toString(), { from: owner })
            if (!mock.minted) {
                mock.minted = { }
            }
            mock.minted[account] = tokensToMint
        }

        const approveToken = async (mock, account, raffleAddress) => {
            const balance = await mock.token.balanceOf(account)
            const balanceTS = balance.toString()
            // console.log(`approving ${balanceTS} from ${account} to ${raffleAddress}`)
            await mock.token.approve(raffleAddress, balanceTS, { from: account })
        }
        
        before(async () => {
            // deploy Chainlinkdatafeeder, if not deployed
            console.log('setting up price oracles...')
            priceOracle = await ChainlinkPriceOracle.deployed()
            priceOracleAddress = priceOracle.address

            await Promise.all([
                setupTokenAndProxy(deploymentSettings.link, LinkMock, LinkAggregatorMock),
                setupTokenAndProxy(deploymentSettings.dai, DaiMock, DaiAggregatorMock),
                setupTokenAndProxy(deploymentSettings.bnb, BnbMock, BnbAggregatorMock)
            ])

            const ethProxy = await EthAggregatorMock.deployed()
            await priceOracle.setEthTokenProxy(ethProxy.address, await ethProxy.decimals());

            await Promise.all([
                assignProxyToOracle(deploymentSettings.link, priceOracle),
                assignProxyToOracle(deploymentSettings.dai, priceOracle),
                assignProxyToOracle(deploymentSettings.bnb, priceOracle)
            ])
            console.log(`price oracles set up at ${priceOracleAddress}`)

            // setup randomness oracle
            console.log('setting up randomness oracle...')
            randomnessOracle = await RandomnessOracleMock.deployed()
            randomnessOracleAddress = randomnessOracle.address
            console.log(`randomness oracle set up at ${randomnessOracleAddress}`)

            // mint some tokenss
            console.log('minting tokens...')
            await Promise.all(accounts.map(async account => {
                await mintToken(account, deploymentSettings.link, owner)
                await mintToken(account, deploymentSettings.dai, owner)
                await mintToken(account, deploymentSettings.bnb, owner)
            }))
            console.log('tokens minted')
        })
        
        beforeEach(async () => {
            // deploy Raffle
            console.log('deploying raffle contract...')
            raffle = await Raffle.new(
                maxPlayers
                , maxTokens
                , ticketFee.toString() // 1,000,000,000 / 1,000,000,000,000,000,000
                , randomnessOracleAddress
                , priceOracleAddress
            )
            raffleAddress = raffle.address
            console.log(`raffle is deployed at ${raffleAddress}`)
            // allow raffle to spend all tokens
            console.log('approving tokens...')
            await Promise.all(accounts.map(async account => {
                await approveToken(deploymentSettings.link, account, raffle.address)
                await approveToken(deploymentSettings.dai, account, raffle.address)
                await approveToken(deploymentSettings.bnb, account, raffle.address)
            }))
            console.log('tokens approved')
        })

        describe('deployment', async () => {
            it('sets ctor parameters', async () => {
                // (await raffle.__getMaxPlayers()).toString().eq(maxPlayers.toString()).should.be.true
                // (await raffle.__getMaxTokens()).toString().eq(maxTokens.toString()).should.be.true
                // (await raffle.__getTicketFee()).toString().eq(ticketFee.toString()).should.be.true
                // expect(await raffle.__getMaxPlayers(), 'maxPlayers').to.eq.BN(new BN(maxPlayers))
                // expect(await raffle.__getMaxTokens(), 'maxTokens').to.eq.BN(new BN(maxTokens))
                // expect(await raffle.__getTicketFee(), 'ticketFee').to.eq.BN(new BN(ticketFee))
                assert.isTrue((await raffle.__getMaxPlayers()).eq(new BN(maxPlayers)), 'maxPlayers')
                assert.isTrue((await raffle.__getMaxTokens()).eq(new BN(maxTokens)), 'maxTokens')
                assert.isTrue((await raffle.__getTicketFee()).eq(new BN(ticketFee)), 'ticketFee')
                assert.equal(await raffle.__getRandomnessOracleAddress(), randomnessOracleAddress, 'randomnessOracleAddress')
                assert.equal(await raffle.__getPriceOracleAddress(), priceOracleAddress, 'priceOracleAddress')
            })
        })

        describe('deposit', async () => {
            const deposits1 = {
                account0: {
                    linkAmount: 1000,
                    // daiAmount: 3000,
                    bnbAmount: 5000
                },
                account1: {
                    linkAmount: 7000,
                    daiAmount: 11000,
                    // bnbAmount: 13000
                },
                account2: {
                    // linkAmount: 17000,
                    daiAmount: 19000,
                    bnbAmount: 23000
                },
                account3: {
                    linkAmount: 29000,
                    daiAmount: 31000,
                    bnbAmount: 37000
                },
                account4: {
                    linkAmount: 37000,
                    // daiAmount: 41000,
                    // bnbAmount: 43000
                }
            }

            const deposits2 = {
                account3: {
                    linkAmount: 101000,
                    // daiAmount: 31000,
                    bnbAmount: 107000
                },
                account4: {
                    linkAmount: 111000,
                    // daiAmount: 41000,
                    bnbAmount: 117000
                }
            }

            const deposits3 = {
                account3: {
                    linkAmount: 555,
                    daiAmount: 777,
                    bnbAmount: 999
                }
            }

            const deposit = async (account, { linkAmount, daiAmount, bnbAmount }, value) => {
                let resultValue = new BN()
                if (linkAmount) {
                    const { tx, logs, receipt } = await raffle.deposit(deploymentSettings.link.tokenAddress, linkAmount, { from: account, value: value })
                    resultValue = resultValue.add(new BN(value))
                }
                if (daiAmount) {
                    const { tx, logs, receipt } = await raffle.deposit(deploymentSettings.dai.tokenAddress, daiAmount, { from: account, value: value })
                    resultValue = resultValue.add(new BN(value))
                }
                if (bnbAmount) {
                    const { tx, logs, receipt } = await raffle.deposit(deploymentSettings.bnb.tokenAddress, bnbAmount, { from: account, value: value })
                    resultValue = resultValue.add(new BN(value))
                }
                return resultValue
            }

            const assertTokensBeforeAfterDepositing = async (account, depo1, depo2, depo3, initialBalance) => {
                let expectedLink = initialBalance.link
                const linkSubN = (depo1 && depo1.linkAmount ? depo1.linkAmount : 0)
                    + (depo2 && depo2.linkAmount ? depo2.linkAmount : 0)
                    + (depo3 && depo3.linkAmount ? depo3.linkAmount : 0)
                expectedLink = expectedLink.subn(linkSubN)
                const actualLink = await deploymentSettings.link.token.balanceOf(account)
                
                let expectedDai = initialBalance.dai
                const daiSubN = (depo1 && depo1.daiAmount ? depo1.daiAmount : 0)
                    + (depo2 && depo2.daiAmount ? depo2.daiAmount : 0)
                    + (depo3 && depo3.daiAmount ? depo3.daiAmount : 0)
                expectedDai = expectedDai.subn(daiSubN)
                const actualDai = await deploymentSettings.dai.token.balanceOf(account)
                
                let expectedBnb = initialBalance.bnb
                const bnbSubN = (depo1 && depo1.bnbAmount ? depo1.bnbAmount : 0)
                    + (depo2 && depo2.bnbAmount ? depo2.bnbAmount : 0)
                    + (depo3 && depo3.bnbAmount ? depo3.bnbAmount : 0)
                expectedBnb = expectedBnb.subn(bnbSubN)
                const actualBnb = await deploymentSettings.bnb.token.balanceOf(account)
                
                // (actualLink.toString().eq(expectedLink.toString())).should.be.true
                // (actualDai.toString().eq(expectedDai.toString())).should.be.true
                // (actualBnb.toString().eq(expectedBnb.toString())).should.be.true
                // expect(actualLink, 'LINK').to.eq.BN(expectedLink)
                // expect(actualDai, 'DAI').to.eq.BN(expectedDai)
                // expect(actualBnb, 'BNB').to.eq.BN(expectedBnb)
                assert.isTrue(actualLink.eq(expectedLink), 'LINK')
                assert.isTrue(actualDai.eq(expectedDai), 'DAI')
                assert.isTrue(actualBnb.eq(expectedBnb), 'BNB')

                return {
                    link: {
                        actual: actualLink,
                        expected: expectedLink,
                        linkSub: linkSubN || 0
                    },
                    dai: {
                        actual: actualDai,
                        expected: expectedDai,
                        daiSub: daiSubN || 0
                    },
                    bnb: {
                        actual: actualBnb,
                        expected: expectedBnb,
                        bnbSub: bnbSubN || 0
                    }
                }
            }

            let feesPaid = new BN(), initialCollectedFee = new BN()
            let initialBalances = {
                account0: { link: new BN(0), dai: new BN(0), bnb: new BN(0) },
                account1: { link: new BN(0), dai: new BN(0), bnb: new BN(0) },
                account2: { link: new BN(0), dai: new BN(0), bnb: new BN(0) },
                account3: { link: new BN(0), dai: new BN(0), bnb: new BN(0) },
                account4: { link: new BN(0), dai: new BN(0), bnb: new BN(0) },
            }

            const recordInitialBalancePerAccount = async (account, initialBalance) => {
                await Promise.all([
                    initialBalance.link = await deploymentSettings.link.token.balanceOf(account),
                    initialBalance.dai = await deploymentSettings.dai.token.balanceOf(account),
                    initialBalance.bnb = await deploymentSettings.bnb.token.balanceOf(account),
                ])
            }

            const recordInitialBalances = async () => {
                console.log('recording initial balances...')
                await Promise.all([
                    recordInitialBalancePerAccount(accounts[0], initialBalances.account0),
                    recordInitialBalancePerAccount(accounts[1], initialBalances.account1),
                    recordInitialBalancePerAccount(accounts[2], initialBalances.account2),
                    recordInitialBalancePerAccount(accounts[3], initialBalances.account3),
                    recordInitialBalancePerAccount(accounts[4], initialBalances.account4),
                ])
                console.log('initial balances are recorded')
            }

            beforeEach(async () => {
                await recordInitialBalances()

                initialCollectedFee = initialCollectedFee.add(await raffle.__getCollectedFee());

                // let all accounts take participation
                feesPaid = feesPaid.add(await deposit(accounts[0], deposits1.account0, ticketFee + 1000))
                feesPaid = feesPaid.add(await deposit(accounts[1], deposits1.account1, ticketFee + 3000))
                feesPaid = feesPaid.add(await deposit(accounts[2], deposits1.account2, ticketFee + 7000))
                feesPaid = feesPaid.add(await deposit(accounts[3], deposits1.account3, ticketFee + 11000))
                feesPaid = feesPaid.add(await deposit(accounts[4], deposits1.account4, ticketFee + 13000))
                // secondary deposits
                feesPaid = feesPaid.add(await deposit(accounts[3], deposits2.account3, ticketFee + 17000))
                feesPaid = feesPaid.add(await deposit(accounts[4], deposits2.account4, ticketFee + 19000))
                // third time deposits
                feesPaid = feesPaid.add(await deposit(accounts[3], deposits3.account3, ticketFee + 23000))

                console.log('tokens deposited')
            })
            it('numbers are valid after depositing', async () => {
                const data = [
                    await assertTokensBeforeAfterDepositing(
                        accounts[0], 
                        deposits1.account0, 
                        deposits2.account0, 
                        deposits3.account0, 
                        initialBalances.account0
                    ),
                    await assertTokensBeforeAfterDepositing(
                        accounts[1], 
                        deposits1.account1, 
                        deposits2.account1, 
                        deposits3.account1, 
                        initialBalances.account1
                    ),
                    await assertTokensBeforeAfterDepositing(
                        accounts[2], 
                        deposits1.account2, 
                        deposits2.account2, 
                        deposits3.account2, 
                        initialBalances.account2
                    ),
                    await assertTokensBeforeAfterDepositing(
                        accounts[3], 
                        deposits1.account3, 
                        deposits2.account3, 
                        deposits3.account3, 
                        initialBalances.account3
                    ),
                    await assertTokensBeforeAfterDepositing(
                        accounts[4], 
                        deposits1.account4, 
                        deposits2.account4, 
                        deposits3.account4, 
                        initialBalances.account4
                    ),
                ]

                // check the contract's balances
                const ctrLinkExpected = data.reduce((prev, current) => { return prev + current.link.linkSub }, 0)
                const ctrLinkAmount = await deploymentSettings.link.token.balanceOf(raffleAddress)
                const ctrDaiExpected = data.reduce((prev, current) => { return prev + current.dai.daiSub }, 0)
                const ctrDaiAmount = await deploymentSettings.dai.token.balanceOf(raffleAddress)
                const ctrBnbExpected = data.reduce((prev, current) => { return prev + current.bnb.bnbSub }, 0)
                const ctrBnbAmount = await deploymentSettings.bnb.token.balanceOf(raffleAddress)
                assert.isTrue(ctrLinkAmount.eq(new BN(ctrLinkExpected)), 'LINK on raffle')
                assert.isTrue(ctrDaiAmount.eq(new BN(ctrDaiExpected)), 'DAI on raffle')
                assert.isTrue(ctrBnbAmount.eq(new BN(ctrBnbExpected)), 'BNB on raffle')
                
                // check collectedFee
                const collectedFee = await raffle.__getCollectedFee()
                assert.isTrue(collectedFee.eq(feesPaid), 'collected fee')

                // check chances
            })
        })
        /*
        describe('withdrawThePrize', async () => {
            it('test', async () => {
                assert(true, true)
            })
        })

        describe('rollTheDice', async () => {
            it('test', async () => {
                assert(true, true)
            })
        })

        describe('rollTheDiceManually', async () => {
            it('test', async () => {
                assert(true, true)
            })
        })

        describe('inputRandomNumberManually', async () => {
            it('test', async () => {
                assert(true, true)
            })
        })

        describe('fixRolling', async () => {
            it('test', async () => {
                assert(true, true)
            })
        })
        */
    } catch(err) {
        console.log('ERR!!', err)
    }
})
