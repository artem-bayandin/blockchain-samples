import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers'
import { expect } from 'chai'
import hre from 'hardhat'
import { BeaconRefName, Implementation1RefName, Implementation2RefName, NamedBeaconProxyRefName } from '../scripts/shared'
import { Beacon, Implementation1, Implementation2, NamedBeaconProxy } from '../typechain-types'
import { ContractTransactionResponse } from 'ethers'
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import { encodeInitData } from './shared'
import { abi as abi1 } from '../artifacts/contracts/Impl.sol/Implementation1.json'
import { abi as abi2 } from '../artifacts/contracts/Impl.sol/Implementation2.json'

const TEST_REF_1 = '0x088b4f879c7de0a72bd8e2e1db4c05646e10ad3f1f6513c52d13fa7c445d1ebc'
const TEST_REF_2 = '0x4ca70862e886132db4ab441006b70464222cb9fee7da3742ddf128dcf1897405'

describe(`NamedBeaconProxy`, function () {
    let beacon: Beacon & {
        deploymentTransaction(): ContractTransactionResponse
    }
    let impl1: Implementation1 & {
        deploymentTransaction(): ContractTransactionResponse;
    }
    let impl2: Implementation2 & {
        deploymentTransaction(): ContractTransactionResponse;
    }
    let proxy1: NamedBeaconProxy & {
        deploymentTransaction(): ContractTransactionResponse;
    }
    let proxy2: NamedBeaconProxy & {
        deploymentTransaction(): ContractTransactionResponse;
    }
    let proxied1: Implementation1
    let proxied2: Implementation2

    const initVal1 = 10
    const initVal2 = 20

    let owner: HardhatEthersSigner
    let account1: HardhatEthersSigner
    let account2: HardhatEthersSigner
    let account3: HardhatEthersSigner

    async function deployFixture() {
        const [owner, account1, account2, account3] = await hre.ethers.getSigners()

        // deploy beacon
        const Beacon = await hre.ethers.getContractFactory(BeaconRefName)
        const beacon = await Beacon.deploy(await owner.getAddress())

        // deploy ver1 impl
        const Impl1 = await hre.ethers.getContractFactory(Implementation1RefName)
        const impl1 = await Impl1.deploy()

        // deploy ver2 impl
        const Impl2 = await hre.ethers.getContractFactory(Implementation2RefName)
        const impl2 = await Impl2.deploy()

        // register references
        let regTx = await beacon.registerImplementation(TEST_REF_1, await impl1.getAddress())
        await regTx.wait()
        regTx = await beacon.registerImplementation(TEST_REF_2, await impl2.getAddress())
        await regTx.wait()

        // deploy proxies
        // function initialize(uint256 _initValue) external initializer
        const beaconAddress = await beacon.getAddress()

        const Proxy = await hre.ethers.getContractFactory(NamedBeaconProxyRefName)
        const proxy1 = await Proxy.deploy(beaconAddress, encodeInitData(abi1, 'initialize', [ initVal1 ]), TEST_REF_1)
        const proxy2 = await Proxy.deploy(beaconAddress, encodeInitData(abi2, 'initialize', [ initVal2 ]), TEST_REF_2)

        const proxied1 = await hre.ethers.getContractAt(Implementation1RefName, await proxy1.getAddress()) as any as Implementation1
        const proxied2 = await hre.ethers.getContractAt(Implementation2RefName, await proxy2.getAddress()) as any as Implementation2

        return { beacon
            , owner
            , account1
            , account2
            , account3
            , impl1
            , impl2
            , proxy1
            , proxy2
            , proxied1
            , proxied2
        }
    }

    beforeEach(async function () {
        ({ beacon
            , owner
            , account1
            , account2
            , account3
            , impl1
            , impl2
            , proxy1
            , proxy2
            , proxied1
            , proxied2
        } = await loadFixture(deployFixture))
    })

    describe(`Deployment`, function () {
        it(`works`, async function () {
            const val1 = Number(await proxied1.getMe())
            const val2 = Number(await proxied2.getMe())
            expect(val1).to.eql(initVal1 * 2)
            expect(val2).to.eql(initVal2 * 3)
        })
    })
})