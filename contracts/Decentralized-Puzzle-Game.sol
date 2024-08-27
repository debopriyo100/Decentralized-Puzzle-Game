// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// ERC-20 Token Contract
contract PuzzleGameToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("PuzzleGameToken", "PGT") {
        _mint(msg.sender, initialSupply);
    }
}

// Puzzle Game Contract
contract PuzzleGame {
    // Reference to the ERC-20 token contract
    IERC20 public token;
    address public admin;

    // Structure for a puzzle
    struct Puzzle {
        string solutionHash;
        bool isSolved;
    }

    // Mappings
    mapping(string => Puzzle) public puzzles; // Puzzle ID to Puzzle
    mapping(address => uint256) public rewards; // Player address to total rewards

    // Events
    event PuzzleAdded(string puzzleId, string solutionHash);
    event PuzzleSolved(address player, string puzzleId, uint256 rewardAmount);

    // Modifier to restrict access to admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    // Constructor
    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
        admin = msg.sender;
    }

    // Function to add a new puzzle
    function addPuzzle(string memory puzzleId, string memory solutionHash) public onlyAdmin {
        require(bytes(puzzles[puzzleId].solutionHash).length == 0, "Puzzle already exists");
        puzzles[puzzleId] = Puzzle(solutionHash, false);
        emit PuzzleAdded(puzzleId, solutionHash);
    }

    // Function for players to solve a puzzle
    function solvePuzzle(string memory puzzleId, string memory solution) public {
        Puzzle storage puzzle = puzzles[puzzleId];
        require(!puzzle.isSolved, "Puzzle already solved");

        // Verify the solution
        bytes32 providedHash = keccak256(abi.encodePacked(solution));
        bytes32 correctHash = keccak256(abi.encodePacked(puzzle.solutionHash));

        if (providedHash == correctHash) {
            puzzle.isSolved = true;
            uint256 rewardAmount = 100 * 10 ** 18; // Example reward: 100 PGT
            rewards[msg.sender] += rewardAmount;
            require(token.transfer(msg.sender, rewardAmount), "Token transfer failed");
            emit PuzzleSolved(msg.sender, puzzleId, rewardAmount);
        }
    }

    // Function for the admin to withdraw tokens from the contract
    function withdrawTokens(uint256 amount) public onlyAdmin {
        uint256 balance = token.balanceOf(address(this));
        require(amount <= balance, "Insufficient contract balance");
        require(token.transfer(msg.sender, amount), "Token transfer failed");
    }
}
