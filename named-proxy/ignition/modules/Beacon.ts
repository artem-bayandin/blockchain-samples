// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { BeaconRefName } from "../../scripts/shared";

const Module = buildModule("DeployBeacon", (m) => {
  // get parameters
  const owner = m.getParameter("owner");
  // deploy smart contract
  const beacon = m.contract(BeaconRefName, [owner]);
  // return result
  return { beacon };
});

export default Module;