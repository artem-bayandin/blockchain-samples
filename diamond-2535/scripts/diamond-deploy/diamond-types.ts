import { BaseContract, ContractFactory, id } from 'ethers'

export const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 }

export interface Selectors {
    contract: BaseContract | ContractFactory
    selectors: string[]
    remove: (functionNames: string[]) => Selectors
    get: (functionNames: string[]) => Selectors
}

export interface DeployedFacet {
    facetImplAddress: string
    action: number
    functionSelectors: Selectors
}

// xStruct is for contract mapping
export interface DiamondLoupeFacetStruct {
    facetAddress: string
    functionSelectors: string[]
}

// xStruct is for contract mapping
export interface FacetCutStruct {
    facetAddress: string
    action: number
    functionSelectors: string[]
}

export const mapDeployedFacetToFacetCut = (deployedFacet: DeployedFacet): FacetCutStruct => {
    return {
        facetAddress: deployedFacet.facetImplAddress,
        action: deployedFacet.action,
        functionSelectors: [ ...deployedFacet.functionSelectors.selectors ]
    }
}

export const funcSignatureToId = (signature: string): string => {
    return id(signature).substring(0, 10)
}
