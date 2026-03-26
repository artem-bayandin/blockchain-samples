import { Interface } from 'ethers'

export function getSelectorsFromInterface(iface: Interface, includeInit: boolean = false): { selectors: string[], functionNames: string[] } {
	const functions = iface
        .fragments
        .filter((f: any) => f.type === 'function') // Fragment
	const functionSignatures = functions.map((f: any) => f.format('sighash')) // functions.map((f: any) => f.name)
	const selectorsArray = functionSignatures
        .filter((funcName: string) => (includeInit || funcName !== 'init'))
        .map((funcName: string) => iface.getFunction(funcName).selector)
	return { selectors: selectorsArray, functionNames: functionSignatures }
}
