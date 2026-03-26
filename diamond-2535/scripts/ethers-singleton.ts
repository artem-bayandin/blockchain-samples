import { HardhatEthers } from '@nomicfoundation/hardhat-ethers/types'
import { NetworkHelpers } from '@nomicfoundation/hardhat-network-helpers/types'
import { network } from 'hardhat'
import { EthereumProvider } from 'hardhat/types/providers'

let ethersInstance: HardhatEthers | null = null
let providerInstance: EthereumProvider | null = null
let networkHelpersInstance: NetworkHelpers<"generic"> | null = null

/**
 * Gets the singleton ethers instance.
 * Initializes it on first call and reuses the same instance for subsequent calls.
 */
export async function getEthers(): Promise<{ ethers: HardhatEthers, provider: EthereumProvider, networkHelpers: NetworkHelpers<"generic"> }> {
	if (ethersInstance === null) {
		const { ethers, provider, networkHelpers } = await network.connect()
		ethersInstance = ethers
		providerInstance = provider
		networkHelpersInstance = networkHelpers
	}
	return { ethers: ethersInstance, provider: providerInstance, networkHelpers: networkHelpersInstance }
}
