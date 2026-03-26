import { network } from 'hardhat'
const { ethers, networkHelpers } = await network.connect()
import { expect } from 'chai'
import { type Signer, ZeroAddress } from 'ethers'
import type { Implementation1, Implementation2, NamedBeacon, NamedBeaconProxy } from '../compiled/types/index.ts'
import { beaconFixture, deployImplementation1, deployImplementation2, deployNamedBeacon, deployProxy, encodeInitData, verifySingleInternalEvent } from './shared.ts'
import { Implementation1RefName, Implementation2RefName, NamedBeaconProxyRefName } from '../scripts/shared.ts'
import Impl1Artifact from '../compiled/artifacts/contracts/Impl.sol/Implementation1.json'
import Impl2Artifact from '../compiled/artifacts/contracts/Impl.sol/Implementation2.json'

const TEST_REF_1 = '0x088b4f879c7de0a72bd8e2e1db4c05646e10ad3f1f6513c52d13fa7c445d1ebc'
const TEST_REF_2 = '0x4ca70862e886132db4ab441006b70464222cb9fee7da3742ddf128dcf1897405'

describe(`NamedBeaconProxy`, function () {
    let ctx: {
        base: {
            // from base
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
        },
        // from local
        proxy1: NamedBeaconProxy,
        proxy1Address: string,
        proxied1: Implementation1,
        proxy2: NamedBeaconProxy,
        proxy2Address: string,
        proxied2: Implementation2,
        initVal1: number,
        initVal2: number,
    }

    async function baseFixture() {
        return await beaconFixture(ethers)
    }

    async function beaconProxyFixture() {
        // get signers
        const ctx = await networkHelpers.loadFixture(baseFixture)

        // register references
        let regTx = await ctx.namedBeacon.registerImplementation(TEST_REF_1, ctx.impl_1_1_Address)
        await regTx.wait()
        regTx = await ctx.namedBeacon.registerImplementation(TEST_REF_2, ctx.impl_2_1_Address)
        await regTx.wait()

        const initVal1 = 10
        const initVal2 = 20

        // deploy proxies
        // function initialize(uint256 _initValue) external initializer
        const { contract: proxy1, contractAddress: proxy1Address } = await deployProxy(
            ethers,
            ctx.namedBeaconAddress,
            TEST_REF_1,
            encodeInitData(Impl1Artifact.abi, 'initialize', [ initVal1 ])
        )
        const proxied1 = await ethers.getContractAt(Implementation1RefName, proxy1Address) as any as Implementation1

        const { contract: proxy2, contractAddress: proxy2Address } = await deployProxy(
            ethers,
            ctx.namedBeaconAddress,
            TEST_REF_2,
            encodeInitData(Impl2Artifact.abi, 'initialize', [ initVal2 ])
        )
        const proxied2 = await ethers.getContractAt(Implementation2RefName, proxy2Address) as any as Implementation2

        return {
            base: ctx,
            proxy1,
            proxy1Address,
            proxied1,
            proxy2,
            proxy2Address,
            proxied2,
            initVal1,
            initVal2,
        }
    }

    beforeEach(async function () {
        ctx = await networkHelpers.loadFixture(beaconProxyFixture)
    })

    describe(`Deployment`, function () {
        it('works', async function () {
            // check refs
            const ref1 = await ctx.base.namedBeacon.getImplementation(TEST_REF_1)
            const ref2 = await ctx.base.namedBeacon.getImplementation(TEST_REF_2)
            expect(ref1).to.eql(ctx.base.impl_1_1_Address)
            expect(ref2).to.eql(ctx.base.impl_2_1_Address)

            // read value from proxies
            const val1 = Number(await ctx.proxied1.getMe())
            const val2 = Number(await ctx.proxied2.getMe())
            expect(val1).to.eql(ctx.initVal1 * 2)
            expect(val2).to.eql(ctx.initVal2 * 3)
        })

        it('another attempt', async () => {
            const proxied1 = await ethers.getContractAt(Implementation1RefName, ctx.proxy1Address) as any as Implementation1
            const val1 = Number(await proxied1.getMe())
            expect(val1).to.eql(ctx.initVal1 * 2)
        })
    })
})
