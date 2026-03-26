import { BaseContract, ContractFactory, Interface } from 'ethers'
import { DiamondLoupeFacetStruct, funcSignatureToId, Selectors } from './diamond-types.js'
import { getSelectorsFromInterface } from '../shared.ts'

// get function selectors from ABI
export function getSelectors(contract: BaseContract | ContractFactory, ctrName: string): Selectors {
	const { selectors, functionNames } = getSelectorsFromInterface(contract.interface)
	if (selectors.length !== functionNames.length) {
		console.log(` -INIT- facet detected: ${ctrName}`)
	}
	// console.log(` => SELECTORS for ${ctrName}:`, selectorsArray)

    return {
        contract,
        selectors,
        remove: remove,
        get: get
    }
}

// used with getSelectors to remove selectors from an array of selectors
// signatures argument is an array of function signatures
export function remove(this: Selectors, signatures: string[]): Selectors {
	const selectors = this.selectors.filter((v: string) => {
		for (const signature of signatures) {
			if (v === funcSignatureToId(signature)) {
				return false
			}
		}
		return true
	})
    return {
        contract: this.contract,
        selectors: selectors,
        remove: this.remove,
        get: this.get
    }
}

// used with getSelectors to get selectors from an array of selectors
// signatures argument is an array of function signatures
function get(this: Selectors, signatures: string[]): Selectors {
	const selectors = this.selectors.filter((v: string) => {
		for (const signature of signatures) {
			if (v === funcSignatureToId(signature)) {
				return true
			}
		}
		return false
	})
	return {
        contract: this.contract,
        selectors: selectors,
        remove: this.remove,
        get: this.get
    }
}

// remove selectors using an array of signatures
export function removeSelectors(selectors: string[], signatures: string[]): string[] {
	const iface = new Interface(signatures.map((v: string) => 'function ' + v))
	const removeSelectors = signatures.map((v: string) => iface.getFunction(v).selector)
	selectors = selectors.filter((v: string) => !removeSelectors.includes(v))
	return selectors
}

// find a particular address position in the return value of diamondLoupeFacet.facets()
export function findAddressIndexInFacets(facetAddress: string, facets: DiamondLoupeFacetStruct[]): number {
	for (let i = 0; i < facets.length; i++) {
		if (facets[i].facetAddress === facetAddress) {
			return i
		}
	}
	return -1;
}
