import { network } from 'hardhat'
const { ethers, networkHelpers } = await network.connect()
import { expect } from 'chai'
import { type Signer, ZeroAddress } from 'ethers'
import type { Implementation1, Implementation2, NamedBeacon } from '../compiled/types/index.ts'
import { beaconFixture, deployImplementation1, deployImplementation2, deployNamedBeacon, verifySingleInternalEvent } from './shared.ts'

const TEST_REF_1 = '0x088b4f879c7de0a72bd8e2e1db4c05646e10ad3f1f6513c52d13fa7c445d1ebc'
const TEST_REF_2 = '0x4ca70862e886132db4ab441006b70464222cb9fee7da3742ddf128dcf1897405'

// event ImplementationRegistered(bytes32 indexed name, address previous, address current)
const EVENT_IMPLEMENTATION_REGISTERED = 'ImplementationRegistered'

describe(`Beacon`, function () {
    let ctx: {
        owner: Signer,
        ownerAddress: string,
        account1: Signer,
        account1Address: string,
        account2: Signer,
        account2Address: string,
        account3: Signer,
        account3Address: string,
        namedBeacon: NamedBeacon,
        namedBeaconAddress: string,
        impl_1_1: Implementation1
        impl_1_1_Address: string
        impl_1_2: Implementation1
        impl_1_2_Address: string
        impl_2_1: Implementation2
        impl_2_1_Address: string
        impl_2_2: Implementation2
        impl_2_2_Address: string
    }

    async function localFixture() {
        return await beaconFixture(ethers)
    }

    beforeEach(async function () {
        ctx = await networkHelpers.loadFixture(localFixture)
    })

    describe('Deployment', function () {
        it('Should set the right owner', async function () {
            expect(await ctx.namedBeacon.owner()).to.equal(ctx.ownerAddress)
        })
    })

    describe('Register and read', async function () {
        it('works', async function () {
            const impl1 = ctx.impl_1_1_Address
            const impl2 = ctx.impl_2_1_Address
            const impl3 = ctx.impl_2_2_Address

            let regTx = await ctx.namedBeacon.registerImplementation(TEST_REF_1, impl1)
            let receipt = await regTx.wait()
            expect(await ctx.namedBeacon.getImplementation(TEST_REF_1)).to.equal(impl1)
            verifySingleInternalEvent(receipt, EVENT_IMPLEMENTATION_REGISTERED, [
				TEST_REF_1,
				ZeroAddress,
				impl1
			])

            regTx = await ctx.namedBeacon.registerImplementation(TEST_REF_2, impl2)
            receipt = await regTx.wait()
            expect(await ctx.namedBeacon.getImplementation(TEST_REF_2)).to.equal(impl2)
            verifySingleInternalEvent(receipt, EVENT_IMPLEMENTATION_REGISTERED, [
				TEST_REF_2,
				ZeroAddress,
				impl2
			])

            regTx = await ctx.namedBeacon.registerImplementation(TEST_REF_1, impl3)
            receipt = await regTx.wait()
            expect(await ctx.namedBeacon.getImplementation(TEST_REF_1)).to.equal(impl3)
            verifySingleInternalEvent(receipt, EVENT_IMPLEMENTATION_REGISTERED, [
				TEST_REF_1,
				impl1,
				impl3
			])
        })

        it('Reverts if run by user', async () => {
            await expect(
                ctx.namedBeacon.connect(ctx.account1).registerImplementation(TEST_REF_1, ctx.account2Address)
            ).to.be.revertedWithCustomError(ctx.namedBeacon, 'UnauthorizedAccess')
        })

        it('Reverts to set impl address if eoa', async () => {
            await expect(
                ctx.namedBeacon.registerImplementation(TEST_REF_1, ctx.account1Address)
            ).to.revertedWithCustomError(ctx.namedBeacon, 'InvalidImplementation')
        })
    })
})
