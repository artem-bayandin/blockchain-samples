const AppBeacon = artifacts.require('AppBeacon')
const NftDataStorage = artifacts.require('NftDataStorage')
const NftImageResolver = artifacts.require('NftImageResolver')
const OnchainNftTokenUriResolver = artifacts.require('OnchainNftTokenUriResolver')
const NftMinter = artifacts.require('NftMinter')
const NftMintingAllowance = artifacts.require('NftMintingAllowance')
const NftManager = artifacts.require('NftManager')

const deployContracts = async (
    deployer, network, accounts
    , _AppBeacon
    , _NftDataStorage
    , _NftImageResolver
    , _OnchainNftTokenUriResolver
    , _NftMinter
    , _NftMintingAllowance
    , _NftManager
) => {
    console.log(`deployig to '${network}'`)

    await deployer.deploy(_AppBeacon)
    const appBeacon = await _AppBeacon.deployed()

    await deployer.deploy(_NftDataStorage, appBeacon.address)
    const nftDataStorage = await _NftDataStorage.deployed()

    await deployer.deploy(_NftImageResolver)
    const nftImageResolver = await _NftImageResolver.deployed()

    await deployer.deploy(_OnchainNftTokenUriResolver, appBeacon.address)
    const onchainNftTokenUriResolver = await _OnchainNftTokenUriResolver.deployed()

    await deployer.deploy(_NftMinter, appBeacon.address, "Upgradeable Onchain NFT", "UONFT")
    const nftMinter = await _NftMinter.deployed()

    await deployer.deploy(_NftMintingAllowance)
    const nftMintingAllowance = await _NftMintingAllowance.deployed()

    await deployer.deploy(_NftManager, appBeacon.address)
    const nftManager = await _NftManager.deployed()

    // register items in appBeacon
    await appBeacon.set("NftDataStorage", nftDataStorage.address)
    await appBeacon.set("NftImageResolver", nftImageResolver.address)
    await appBeacon.set("NftTokenUriResolver", onchainNftTokenUriResolver.address)
    await appBeacon.set("NftMinter", nftMinter.address)
    await appBeacon.set("NftMintingAllowance", nftMintingAllowance.address)
    await appBeacon.set("NftManager", nftManager.address)

    console.log({
        'appBeacon address': appBeacon.address,
        'nftDataStorage address': [
                nftDataStorage.address
                , await appBeacon.get('NftDataStorage')
        ],
        'nftImageResolver address': [
                nftImageResolver.address
                , await appBeacon.get('NftImageResolver')
        ],
        'onchainNftTokenUriResolver address': [
                onchainNftTokenUriResolver.address
                , await appBeacon.get('NftTokenUriResolver')
        ],
        'nftMinter address': [
                nftMinter.address
                , await appBeacon.get('NftMinter')
        ],
        'nftMintingAllowance address': [
                nftMintingAllowance.address
                , await appBeacon.get('NftMintingAllowance')
        ],
        'nftManager address': [
                nftManager.address
                , await appBeacon.get('NftManager')
        ]
    })

    console.log({
        'all registered beacon keys': await appBeacon.getList()
    })
}

module.exports = async function (deployer, network, accounts) {
    if (network === 'development') {
        await deployContracts(
            deployer, network, accounts
            , AppBeacon
            , NftDataStorage
            , NftImageResolver
            , OnchainNftTokenUriResolver
            , NftMinter
            , NftMintingAllowance
            , NftManager
        )
    }
}
