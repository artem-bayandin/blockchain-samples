// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { NamedBeaconProxyRefName } from "../../scripts/shared";

const Module = buildModule("DeployNamedBeaconProxy", (m) => {
  // get parameters
  const beacon = m.getParameter("beacon");
  const data = m.getParameter("data");
  const implementationName = m.getParameter("implementationName");
  // deploy smart contract
  const namedBeaconProxy = m.contract(NamedBeaconProxyRefName, [beacon, data, implementationName]);
  // return result
  return { namedBeaconProxy };
});

export default Module;