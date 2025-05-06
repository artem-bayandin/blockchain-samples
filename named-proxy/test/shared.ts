import { expect } from 'chai'
import { ethers } from 'hardhat'

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

// Used when deploying proxy and needs to init the data witing the same tx
export const encodeInitData = (contractAbi: any, methodName: string, args: any[]) => {
	const iface = new ethers.Interface(contractAbi)
	return iface.encodeFunctionData(methodName, args)
}