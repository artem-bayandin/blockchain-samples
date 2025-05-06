import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers'
import { expect } from 'chai'
import hre from 'hardhat'
import { BeaconRefName } from '../scripts/shared'
import { Beacon } from '../typechain-types'
import { ContractTransactionResponse, ZeroAddress } from 'ethers'
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import { verifyEvent } from './shared'

const TEST_REF_1 = '0x088b4f879c7de0a72bd8e2e1db4c05646e10ad3f1f6513c52d13fa7c445d1ebc'
const TEST_REF_2 = '0x4ca70862e886132db4ab441006b70464222cb9fee7da3742ddf128dcf1897405'

// event ImplementationRegistered(bytes32 indexed name, address previous, address current)
const EVENT_IMPLEMENTATION_REGISTERED = 'ImplementationRegistered'

describe(`Beacon`, function () {
    let beacon: Beacon & {
        deploymentTransaction(): ContractTransactionResponse
    }
    let owner: HardhatEthersSigner
    let account1: HardhatEthersSigner
    let account2: HardhatEthersSigner
    let account3: HardhatEthersSigner

    async function deployFixture() {
        const [owner, account1, account2, account3] = await hre.ethers.getSigners()

        const Beacon = await hre.ethers.getContractFactory(BeaconRefName)
        const beacon = await Beacon.deploy(await owner.getAddress())

        return { beacon, owner, account1, account2, account3 }
    }

    beforeEach(async function () {
        ({ beacon, owner, account1, account2, account3 } = await loadFixture(deployFixture))
    })

    describe(`Deployment`, function () {
        it(`Should set the right owner`, async function () {
            expect(await beacon.owner()).to.equal(await owner.getAddress())
        })
    })

    describe(`Register and read`, async function () {
        it(`works`, async function () {
            const impl1 = await account1.getAddress()
            const impl2 = await account2.getAddress()
            const impl3 = await account3.getAddress()

            let regTx = await beacon.registerImplementation(TEST_REF_1, impl1)
            let receipt = await regTx.wait()
            expect(await beacon.getImplementation(TEST_REF_1)).to.equal(impl1)
            verifyEvent(receipt, EVENT_IMPLEMENTATION_REGISTERED, [
				TEST_REF_1,
				ZeroAddress,
				impl1
			])

            regTx = await beacon.registerImplementation(TEST_REF_2, impl2)
            receipt = await regTx.wait()
            expect(await beacon.getImplementation(TEST_REF_2)).to.equal(impl2)
            verifyEvent(receipt, EVENT_IMPLEMENTATION_REGISTERED, [
				TEST_REF_2,
				ZeroAddress,
				impl2
			])

            regTx = await beacon.registerImplementation(TEST_REF_1, impl3)
            receipt = await regTx.wait()
            expect(await beacon.getImplementation(TEST_REF_1)).to.equal(impl3)
            verifyEvent(receipt, EVENT_IMPLEMENTATION_REGISTERED, [
				TEST_REF_1,
				impl1,
				impl3
			])
        })

        it(`Reverts under user`, async () => {
            const impl1 = await account1.getAddress()
            await expect(beacon.connect(account1).registerImplementation(TEST_REF_1, impl1))
				.to.be.reverted
        })
    })
})