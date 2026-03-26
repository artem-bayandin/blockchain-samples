import { getSelectors } from './diamond-lib.js'
import { FacetCutAction, mapDeployedFacetToFacetCut, DeployedFacet, FacetCutStruct } from './diamond-types.js'
import { HardhatEthers } from '@nomicfoundation/hardhat-ethers/types'
import { ZeroAddress } from 'ethers'

export async function deployDiamondAndCutFacet(
	ethers: HardhatEthers,
	contractOwnerAddress: string,
	diamondName: string,
	diamondCutFacetName: string,
	diamondCutAddress: string = '', // if you have already deployed this before and wish to use previous contracts
	diamondAddress: string = '',    // - the same -
): Promise<{ diamondAddress: string, diamondCutFacetImplAddress: string }> {
	let diamondCutFacetImplAddress: string = ''
	if (!diamondCutAddress) {
		// deploy DiamondCutFacet
		const DiamondCutFacet = await ethers.getContractFactory(diamondCutFacetName)
		const diamondCutFacet = await DiamondCutFacet.deploy()
		await diamondCutFacet.waitForDeployment()
    	const deployTx1 = diamondCutFacet.deploymentTransaction()
    	const receipt1 = await deployTx1?.wait()
		diamondCutFacetImplAddress = await diamondCutFacet.getAddress()
	} else {
		diamondCutFacetImplAddress = diamondCutAddress
	}

	// deploy MyDiamond
	if (!diamondAddress) {
		const Diamond = await ethers.getContractFactory(diamondName)
		const diamond = await Diamond.deploy(contractOwnerAddress, diamondCutFacetImplAddress)
		await diamond.waitForDeployment()
		const deployTx2 = diamond.deploymentTransaction()
		const receipt2 = await deployTx2?.wait()
		diamondAddress = await diamond.getAddress()
	}

	return {
		diamondAddress
		, diamondCutFacetImplAddress
	}
}

export async function deployFacet(
	ethers: HardhatEthers,
	action: number,
	facetName: string,
	facetAddress: string = ''
): Promise<DeployedFacet> {
	let facetImplAddress: string = ''
	let facet: any
	if (!facetAddress) {
		const Facet = await ethers.getContractFactory(facetName)
		facet = await Facet.deploy()
		await facet.waitForDeployment()
		const deployTx1 = facet.deploymentTransaction()
    	const receipt1 = await deployTx1?.wait()
		facetImplAddress = await facet.getAddress()
	} else {
		facetImplAddress = facetAddress
		facet = await ethers.getContractAt(facetName, facetAddress)
		console.log('facet read', facetName)
	}
	const result = {
		facetImplAddress,
		action: action,
		functionSelectors: getSelectors(facet, facetName)
	}
	// console.log(`${result.functionSelectors.selectors.length} selectors found for ${facetName}`)
	return result
}

export async function cutFacet(
	ethers: HardhatEthers,
	cut: DeployedFacet[],
	diamondAddress: string,
	facetName: string = '',
): Promise<void> {
	const mapped = cut.map(mapDeployedFacetToFacetCut)
	await cutFacetMapped(ethers, mapped, diamondAddress, facetName)
}

export async function cutFacetMapped(
	ethers: HardhatEthers,
	cut: FacetCutStruct[],
	diamondAddress: string,
	facetName: string = '',
): Promise<void> {
	// upgrade diamond with facets
	const diamondCut = await ethers.getContractAt('IDiamondCut', diamondAddress)
	const tx = await diamondCut.diamondCut(cut, ZeroAddress, '0x')
	const receipt = await tx.wait()
	if (!receipt.status) {
		throw Error(`Diamond upgrade failed: ${tx.hash}, receipt: ${receipt}`)
	}
}

export async function deployAndCutFacet(
	ethers: HardhatEthers,
	diamondAddress: string,
	facetName: string,
	action = FacetCutAction.Add,
): Promise<{ facetImplAddress: string }> {
	const facetData = await deployFacet(ethers, action, facetName)
	await cutFacet(ethers, [facetData], diamondAddress, facetName)
	return { facetImplAddress: facetData.facetImplAddress }
}

export async function deployDiamondInitializer(
	ethers: HardhatEthers,
	diamondAddress: string,
	initFacetName: string,

	// // params to pass into the 'init' function, optional
	// ownerAddress: string,
	// isPaused: boolean,

	// // object params, optional
	// basePrice: number,
	// minPrice: number,
	// maxPrice: number,
): Promise<{ diamondInitImplAddress: string }> {
    // deploy DiamondInit
    // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
    // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
    const DiamondInit = await ethers.getContractFactory(initFacetName)
    const diamondInit = await DiamondInit.deploy()
    await diamondInit.waitForDeployment()
	const deployTx1 = diamondInit.deploymentTransaction()
    const receipt1 = await deployTx1?.wait()
    const diamondInitImplAddress = await diamondInit.getAddress()

    const diamondCut = await ethers.getContractAt('IDiamondCut', diamondAddress)

    let functionCall = diamondInit.interface.encodeFunctionData('init', [
		// ownerAddress,
		// isPaused,

        // if an object is expected, you need to pass it as an array
        // [ basePrice, minPrice, maxPrice ],
	])

    const tx = await diamondCut.diamondCut([], diamondInitImplAddress, functionCall)
    const receipt = await tx.wait()
    if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}, ${receipt}`)
    }
    return { diamondInitImplAddress }
}
