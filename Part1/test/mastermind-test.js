//[assignment] write your own unit test to show that your Mastermind variation circuit is working as expected
const chai = require("chai");
const path = require("path");
const { ethers } = require("hardhat");

const wasm_tester = require("circom_tester").wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
const buildPoseidon = require("circomlibjs").buildPoseidon;

exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

const assert = chai.assert;

describe("Mastermind circuit test", async() => {
  let circuit;

  beforeEach(async () => {
    circuit = await wasm_tester("contracts/circuits/MastermindVariation.circom");
    await circuit.loadConstraints();
  
    poseidonJs = await buildPoseidon();
  });

  it("MastermindVariation Circuit test", async () => {
    
    // Player1: privSolutionColor & pubSolnHash
    const privSolutionColor = [1, 5, 3, 2, 6];
    const privSalt = ethers.BigNumber.from(ethers.utils.randomBytes(32));

    // Player 1: pubSolnHash
    const pubSolnHash = ethers.BigNumber.from(
      poseidonJs.F.toObject(poseidonJs([privSalt, ...privSolutionColor]))
    );

    // Player 2: Makes Guess
    const pubGuessColor = [1, 3, 2, 4, 6];

    // Player 1: Runs the Circuit
    const INPUT = {
      "pubGuessColorA" : pubGuessColor[0].toString(),
      "pubGuessColorB" : pubGuessColor[1].toString(),
      "pubGuessColorC" : pubGuessColor[2].toString(),
      "pubGuessColorD" : pubGuessColor[3].toString(),
      "pubGuessColorE" : pubGuessColor[4].toString(),
      "pubRedPegs" : "2",
      "pubWhitePegs" : "2",
      "pubSolnHash" : pubSolnHash,
      "privSolnColorA" : privSolutionColor[0].toString(),
      "privSolnColorB" : privSolutionColor[1].toString(),
      "privSolnColorC" : privSolutionColor[2].toString(),
      "privSolnColorD": privSolutionColor[3].toString(),
      "privSolnColorE": privSolutionColor[4].toString(),
      "privSalt" : privSalt,
    }
    
    let witness;
    witness = await circuit.calculateWitness(INPUT, true);
  
    // console.log("Fr.e(1): ", Fr.e(1));
    // console.log("witness[1] :", witness[1])
  
    await circuit.checkConstraints(witness);

    // Assert that the outputs are valid
    assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
    assert(Fr.eq(Fr.e(witness[1]), Fr.e(pubSolnHash)));
  });
});