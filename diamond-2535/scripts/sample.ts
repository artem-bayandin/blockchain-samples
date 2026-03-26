import { cutFacet, deployDiamondAndCutFacet, deployDiamondInitializer, deployFacet } from './diamond-deploy/diamond-deploy.ts'
import { FacetCutAction } from './diamond-deploy/diamond-types.ts'
import { getEthers } from './ethers-singleton.ts'
const { ethers } = await getEthers()


const [owner] = await ethers.getSigners()
const ownerAddress = await owner.getAddress()

// deploy base diamond, required
const { diamondAddress, diamondCutFacetImplAddress } = await deployDiamondAndCutFacet(
    ethers,
    ownerAddress,
    'Diamond', // diamond contract name, you will use your own Diamond
    'DiamondCutFacet', // default diamondCutFacet contract, no need to change
)

// deploy loupe facet, required
const loupeDeployedFacet = await deployFacet(
    ethers,
    FacetCutAction.Add,
    'DiamondLoupeFacet', // default diamondLoupeFacet contract, no need to change
)
const loupeFacetImplAddress = loupeDeployedFacet.facetImplAddress

// deploy other facets, optional
// skip for now

// when all facets are deployed - cut them
// otherwise, you might have used function 'deployAndCutFacet', and it'll do the same job

await cutFacet(
    ethers,
    [ loupeDeployedFacet ],
    diamondAddress,
    ['DiamondLoupeFacet'].join(', ') // this is optional, you may remove it, but I used to console.log the data i've deployed
)

// now we need to initialize the diamond
// for this, there is a 'DiamondInit' contract, but you will have your own
const { diamondInitImplAddress } = await deployDiamondInitializer(
    ethers,
    diamondAddress,
    'DiamondInit',
)

// that's it
// have fun!

console.log('Diamond deployment completed.')
console.log('Addresses:', {
    ownerAddress,
    diamondAddress,
    diamondCutFacetImplAddress,
    loupeFacetImplAddress,
    diamondInitImplAddress,
})
