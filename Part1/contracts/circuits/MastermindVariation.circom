pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

// Implementation of Mastermind44: 6 colors, 5 holes

template MastermindVariation() {
    // Public inputs
    signal input pubGuessColorA;
    signal input pubGuessColorB;
    signal input pubGuessColorC;
    signal input pubGuessColorD;
    signal input pubGuessColorE;

    signal input pubRedPegs;
    signal input pubWhitePegs;
    signal input pubSolnHash;

    // Private inputs
    signal input privSolnColorA;
    signal input privSolnColorB;
    signal input privSolnColorC;
    signal input privSolnColorD;
    signal input privSolnColorE;

    signal input privSalt;

    // Output
    signal output solnHashOut;

    var guess[5] = [pubGuessColorA, pubGuessColorB, pubGuessColorC, pubGuessColorD, pubGuessColorE];
    var soln[5] =  [privSolnColorA, privSolnColorB, privSolnColorC, privSolnColorD, privSolnColorE];
    var j = 0;
    var k = 0;
    component lessThan[10];

    component equalGuess[10];
    component equalSoln[10];
    var equalIdx = 0;

    // Create a constraint that the solution and guess digits are all less than 6.
    for (j=0; j<5; j++) {
        lessThan[j] = LessThan(4);
        lessThan[j].in[0] <== guess[j];
        lessThan[j].in[1] <== 8;
        lessThan[j].out === 1;
        lessThan[j+5] = LessThan(4);
        lessThan[j+5].in[0] <== soln[j];
        lessThan[j+5].in[1] <== 8;
        lessThan[j+5].out === 1;
        for (k=j+1; k<5; k++) {
            // Create a constraint that the solution and guess colors are unique. no duplication.
            equalGuess[equalIdx] = IsEqual();
            equalGuess[equalIdx].in[0] <== guess[j];
            equalGuess[equalIdx].in[1] <== guess[k];
            equalGuess[equalIdx].out === 0;
            equalSoln[equalIdx] = IsEqual();
            equalSoln[equalIdx].in[0] <== soln[j];
            equalSoln[equalIdx].in[1] <== soln[k];
            equalSoln[equalIdx].out === 0;
            equalIdx += 1;
        }
    }


    // Count redPegs & whitePegs
    var redPegs = 0;
    var whitePegs = 0;
    component equalRW[25];

    for (j=0; j<5; j++) {
        for (k=0; k<5; k++) {
            equalRW[5*j+k] = IsEqual();
            equalRW[5*j+k].in[0] <== soln[j];
            equalRW[5*j+k].in[1] <== guess[k];
            whitePegs += equalRW[5*j+k].out;
            if (j == k) {
                redPegs += equalRW[5*j+k].out;
                whitePegs -= equalRW[5*j+k].out;
            }
        }
    }

    // Create a constraint around the number of redPegs
    component equalRedPegs = IsEqual();
    equalRedPegs.in[0] <== pubRedPegs;
    equalRedPegs.in[1] <== redPegs;
    equalRedPegs.out === 1;
    
    // Create a constraint around the number of whitePegs
    component equalWhitePegs = IsEqual();
    equalWhitePegs.in[0] <== pubWhitePegs;
    equalWhitePegs.in[1] <== whitePegs;
    equalWhitePegs.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(6);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSolnColorA;
    poseidon.inputs[2] <== privSolnColorB;
    poseidon.inputs[3] <== privSolnColorC;
    poseidon.inputs[4] <== privSolnColorD;
    poseidon.inputs[5] <== privSolnColorE;

    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;
 }

 component main {public [pubGuessColorA, pubGuessColorB, pubGuessColorC, pubGuessColorD, pubGuessColorE, pubRedPegs, pubWhitePegs, pubSolnHash]} = MastermindVariation();