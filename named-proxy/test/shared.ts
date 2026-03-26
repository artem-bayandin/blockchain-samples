/************************************************************************************************\
* Author: Artem Bayandin <bayandin.artem.official@gmail.com> (https://github.com/artem-bayandin) *
\************************************************************************************************/

import { network } from 'hardhat'
const { ethers } = await network.connect()
import { EventLog, id, Indexed, Interface, keccak256, Log, toUtf8Bytes } from 'ethers'
import { expect } from 'chai'
import { fail } from 'assert'
import type { Implementation1, Implementation2, NamedBeacon } from '../compiled/types/index.ts'
import { Implementation1RefName, Implementation2RefName, NamedBeaconProxyRefName, NamedBeaconRefName } from '../scripts/shared.ts'
import { HardhatEthers } from '@nomicfoundation/hardhat-ethers/types'

/* FIXTURES */

export async function beaconFixture(ethers: HardhatEthers) {
	// get signers
	const [owner, account1, account2, account3] = await ethers.getSigners()
	const ownerAddress = await owner.getAddress()
	const account1Address = await account1.getAddress()
	const account2Address = await account2.getAddress()
	const account3Address = await account3.getAddress()

	// deploy beacon
	const { namedBeacon, namedBeaconAddress } = await deployNamedBeacon(ethers, ownerAddress)

	// deploy some implementations
	const { implementation: impl_1_1, implementationAddress: impl_1_1_Address } = await deployImplementation1(ethers)
	const { implementation: impl_1_2, implementationAddress: impl_1_2_Address } = await deployImplementation1(ethers)
	const { implementation: impl_2_1, implementationAddress: impl_2_1_Address } = await deployImplementation2(ethers)
	const { implementation: impl_2_2, implementationAddress: impl_2_2_Address } = await deployImplementation2(ethers)

	return {
		owner,
		ownerAddress,
		account1,
		account1Address,
		account2,
		account2Address,
		account3,
		account3Address,
		namedBeacon,
		namedBeaconAddress,
		impl_1_1,
		impl_1_1_Address,
		impl_1_2,
		impl_1_2_Address,
		impl_2_1,
		impl_2_1_Address,
		impl_2_2,
		impl_2_2_Address,
	}
}

/* FIXTURES end */

/* DEPLOYMENT */

export async function deployNamedBeacon(ethers: HardhatEthers, ownerAddress: string): Promise<{ namedBeacon: NamedBeacon, namedBeaconAddress: string }> {
    const NamedBeaconFactory = await ethers.getContractFactory(NamedBeaconRefName)
    const namedBeacon = await NamedBeaconFactory.deploy(ownerAddress)
    await namedBeacon.waitForDeployment()
    const deployTx = namedBeacon.deploymentTransaction()
    await deployTx?.wait()
    const namedBeaconAddress = await namedBeacon.getAddress()
    return { namedBeacon, namedBeaconAddress }
}

async function deployWithEmptyCtor(ethers: HardhatEthers, contractName: string): Promise<{ contract: any, contractAddress: string }> {
    const Factory = await ethers.getContractFactory(contractName)
    const contract = await Factory.deploy()
    await contract.waitForDeployment()
    const deployTx = contract.deploymentTransaction()
    await deployTx?.wait()
    const contractAddress = await contract.getAddress()
    return { contract, contractAddress }
}

export async function deployImplementation1(ethers: HardhatEthers): Promise<{ implementation: Implementation1, implementationAddress: string }> {
    const { contract: implementation, contractAddress: implementationAddress } = await deployWithEmptyCtor(ethers, Implementation1RefName)
    return { implementation, implementationAddress }
}

export async function deployImplementation2(ethers: HardhatEthers): Promise<{ implementation: Implementation2, implementationAddress: string }> {
    const { contract: implementation, contractAddress: implementationAddress } = await deployWithEmptyCtor(ethers, Implementation2RefName)
    return { implementation, implementationAddress }
}

export async function deployProxy(ethers: HardhatEthers, beaconAddress: string, implementationName: string, data: string) {
	const Factory = await ethers.getContractFactory(NamedBeaconProxyRefName)
	const contract = await Factory.deploy(beaconAddress, implementationName, data)
	await contract.waitForDeployment()
    const deployTx = contract.deploymentTransaction()
    await deployTx?.wait()
    const contractAddress = await contract.getAddress()
    return { contract, contractAddress }
}

/* DEPLOYMENT end */

/* VERIFIERS */

// Helper function to verify events
export function verifyEvent(receipt: any, eventName: string, expectedArgs: any[]) {
	const event = receipt.logs.find((e: any) => e instanceof ethers.EventLog && e.fragment.name === eventName)
	expect(event).to.not.be.undefined
	if (event instanceof ethers.EventLog) {
		expectedArgs.forEach((arg, index) => {
			expect(event.args[index]).to.equal(arg)
		})
	}
}

// Helper function to verify events
export function verifySingleInternalEvent(receipt: any, eventName: string, expectedArgs: any[]) {
	const events = receipt.logs.filter((e: any) => e instanceof EventLog && e.fragment.name === eventName)
	expect(events.length).to.eql(1, `0 or 2+ ${eventName} events found`)
	const ev = events[0]
	expectedArgs.forEach((arg, index) => {
		// when indexed, we can't compare them directly, so we need to compare their hashes
		const indexed = ev.args[index] instanceof Indexed
		if (indexed) {
			expect((ev.args[index] as Indexed).hash).to.equal(getHashOfString(arg), `invalid indexed argument '${arg}' on ${eventName} event`)
		} else {
			expect(ev.args[index]).to.equal(arg, `invalid non-indexed argument '${arg}' on ${eventName} event`)
		}
	})
}

export function verifyOneOfMultiInternalEvents(receipt: any, eventName: string, expectedArgs: any[]) {
	const ev = receipt.logs.find(
		(e: any) =>
			e instanceof EventLog
			&& e.fragment.name === eventName
			&& e.args?.length === expectedArgs.length
			&& expectedArgs.every((val: any, index: number) => { return e.args[index] == val })
	)
	expect(ev).to.not.undefined
}

/// @dev
/// @param expectedArgs: some data if exists, otherwise '' to skip the positioned argument
export function verifyExternalEvent(receipt: any, abi: any, eventIface: string, expectedArgs: any[]) {
	// ethers_id
	const topicId = id(eventIface)
	/// @dev
	// e.topics[0] - event keccak like keccak(MyEvent(address,uint256))
	// e.topics[1+] - indexed values
	// e.data - packed data (other event parameters)
	const logs = receipt.logs.filter((e: any) => e instanceof Log && e.topics[0] === topicId)
	// short circuit break
	expect(logs.length).to.be.gt(0, `event '${eventIface}' not found by name`)

	let iface = new Interface(abi);
	const parsedEvents = logs
	// just parse
	.map((log: any) => iface.parseLog(log))
	// cut anything but name and args
	.map((log: any) => { return { name: log.name, args: log.args } })
	
	// validate args
	const filteredEvents = parsedEvents
	.filter((ev: any) => expectedArgs.every((arg: any, index: number) => { return !arg || ev.args[index] == arg }))
	switch (filteredEvents.length) {
		case 1:
			return;
		case 0:
			fail(`event '${eventIface}' found, but has some invalid parameters`)
		default:
			fail(`event '${eventIface}' found more than once`)
	}
}

// TODO: verify that this is used correctly
export function verifyNoInternalEvent(receipt: any, eventName: string) {
	const event = receipt.logs.find((e: any) => e instanceof EventLog && e.fragment.name === eventName)
	expect(event).to.be.undefined
}

// TODO: verify that this is used correctly
export function verifyNoExternalEvent(receipt: any, eventIface: string, expectedArgs: any[] = [], abi: any | undefined = undefined) {
	// ethers_id
	const topicId = id(eventIface)
	/// @dev
	// e.topics[0] - event keccak like keccak(MyEvent(address,uint256))
	// e.topics[1+] - indexed values
	// e.data - packed data (other event parameters)
	const logs = receipt.logs.filter((e: any) => e instanceof Log && e.topics[0] === topicId)
	if (!expectedArgs.length) {
		expect(logs.length).to.eql(0, `event '${eventIface}' found when shouldn't`)
		return;
	}

	let iface = new Interface(abi);
	const parsedEvents = logs
	// just parse
	.map((log: any) => iface.parseLog(log))
	// cut anything but name and args
	.map((log: any) => { return { name: log.name, args: log.args } })

	// validate args
	const filteredEvents = parsedEvents
	.filter((ev: any) => expectedArgs.every((arg: any, index: number) => { return !arg || ev.args[index] == arg })) 
	expect(filteredEvents.length).to.eql(0, `event '${eventIface}' found with exact params, when shouldn't`)
}

export function verifyAllEventsByNames(receipt: any, internalEventNames: string[], externalEventInterface: string[]) {
	const num = internalEventNames.length + externalEventInterface.length
	expect(receipt.logs.length).to.eql(num, `invalid number of events: ${receipt.logs.length} instead of ${num}`)

	const internalEvents = receipt.logs.filter(
		(e: any) =>
			e instanceof EventLog
			&& !!(internalEventNames.find((name: string) => name === e.fragment.name))
	)
	expect(internalEvents.length).to.eql(internalEventNames.length, `invalid number of internal events: ${internalEvents.length} instead of ${internalEventNames.length}`)

	const externalEvents = receipt.logs.filter(
		(e: any) =>
			e instanceof Log
			&& !!(externalEventInterface
				.map((ev: string) => id(ev))
				.find((topicId: string) => e.topics[0] === topicId))
	)
	expect(externalEvents.length).to.eql(externalEventInterface.length, `invalid number of external events: ${externalEvents.length} instead of ${externalEventInterface.length}`)
}

/* VERIFIERS end */

/* HELPERS */

// Used when deploying proxy and needs to init the data witing the same tx
export const encodeInitData = (contractAbi: any, methodName: string, args: any[]) => {
	const iface = new ethers.Interface(contractAbi)
	return iface.encodeFunctionData(methodName, args)
}

export function getHashOfString(str: string) {
	return keccak256(toUtf8Bytes(str))
}

/* HELPERS end */
