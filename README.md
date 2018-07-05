# bachelor_project2018
Aimed at providing an algorithm that takes in a grammar definition in Rascal and creates from this a state-based syntax highlighter for various editors. Fails to do so properly

## Contents
This is just the project that I have been working in. It is as of yet not nicely refactored and commented yet. Just here and there is something written that should contribute to the understanding of the code.

### Breakdown
The target algorithm can be divided in a view parts:

	* Take the original grammar and rewrite it to a Strongly Regular Grammar (SRG)
		- This accepts a superset of the original grammar
	* Map SRG to a set of StateMachines (Non-Deterministic). Every Symbol, Production and SubSymbol gets its own machine. returning a map[Symbol, StateMachine]
		- These NFSM's contain as alphabetic tokens the Terminal symbols, but also the higher level Symbols
		- The idea is that when we decide we want to transition from state A to B by a Non-Terminal we push the Machine of this Non-Terminal on the stack of Contexts, parse this Non-Terminal, then pop this Machine from the stack and continue where we left off. 
	* All these Non-Deterministic State Machines are then converted to Deterministic ones
	* The final step consists of mapping the states of the DFSMs to a context used by the syntax highlighters. Merge these to the SyntaxHighlighter datatype and you can generate a syntax highlighting file for for example Sublime Text.
		- This mapping has a number of properties:
			- Terminal tokens can be parsed, coloured and then we advance from context A to B within the same DFSM. Something like:
			```
				DFSM_State_A:
					- match: '{{Terminal}}'
					  set: DFSM_State_B
			```
			- If the target state is a final state and has no outgoing transitions we need to pop the current context off of the stack
			```
				DFSM_State_A_:
					- match: '{{Terminal_Leading_To_Final_Sink}}'
					  pop: true
			```
			- If the target state is final, but has outgoing transitions we need some determining mechanism that says either pop or continue in this machine
			- If the token is NonTerminal we need to recursively find the possible initial TerminalTokens for all these NonTerminal DFSMs. Based on the one we find by lookahead we can determine to what context we need to go next


## Where to find what
	* src::grammar
		Rewrite rules and convert a grammar to a strongly regular one.
	* src::graph
		Has functions for creating strongly connected components for a graph and also from a grammar.
	* src::syntax_highlighting
		Contains beginnings of the work on converting the machines to the syntax highlighters. Generating regular expressions for the symbols, determining to which DFSM to go proves difficult enough.
	* src::grammar2dfa
		Contains files on generating all the Finite State machines from grammars.
		* ::automata 
			StateMachine functionality, datatypes, printers, etc
		* ::confllicts
			Functions that solve the conflicts that arise in the machines
	* src::grammars
		Some grammars to test the functionality on
	* src::symbols
		Files that have functions on Symbol datatype that Rascal uses
	* src::Main
		Main function that calls all the appropriate functions, here you can choose a grammar and type of output. Shows how to use the rest
	* src::Grammar2Highlighter
		Toplevel-function that calls the rest, this could be called from the terminal
	* src::TerminalRunCode
		Some examples used for testing that could be copied and pasted in the terminal

