module Grammar2Highlighter

import Prelude;

import graph::Grammar2Graph;
import grammar::strongly_regular_grammar::StronglyRegularGrammar;
import grammar::rewrite_grammar::ToPlainGrammar;

import grammar2dfa::automata::StateMachine;
import grammar2dfa::automata::NFA2DFA;
import grammar2dfa::ComponentMachines;

import grammar2dfa::conflicts::ConflictSolving;
import grammar2dfa::conflicts::ComponentTree;

import syntax_highlighting::syntax_highlighter::SyntaxHighlighter;
import syntax_highlighting::syntax_highlighter::ToSyntaxHighlighter;
import syntax_highlighting::SublimeText::ToSublimeSyntax;

map[Symbol, StateMachine] getConflictlessComponentMachines(Grammar strRegular) {
	set[set[Symbol]] str_regular_components = grammar2strConnectedComponents(strRegular);
	NTree[set[Symbol]] str_regular_comp_tree = toComponentTree(strRegular);
	map[Symbol, StateMachine] nfas = generateComponentNFAs(strRegular, str_regular_components);
	map[Symbol, StateMachine] dfas = (s:NFA2DFA(nfas[s]) | s <- nfas);
	//print some statistics
	int oldnumstates = (0 | it + size(getStates(dfas[d])) | d <- dfas);
	println("number of states in initial dfas: <oldnumstates>");
	println("number of dfas <size(dfas)>");
	println("number of components <size(str_regular_components)>");
	//Conflict solving
	dfas = solveAllConflicts(str_regular_comp_tree, dfas, str_regular_components);
	
	//More statistics
	int newnumstates = (0 | it + size(getStates(dfas[d])) | d <- dfas);
	println("new numstates: <newnumstates>, old: <oldnumstates>");
	
	return dfas;
}

void grammar2highlighter(Grammar g, str name, set[str] file_extensions) {
	//Rebuild grammar, make statemachines
	Grammar strRegular = toStronglyRegularGrammar(g);
	map[Symbol, StateMachine] dfas = getConflictlessComponentMachines(strRegular);
	assert(size(g.starts) == 1);
	Symbol startSymbol = takeOneFrom(g.starts)[0];

	//ToSyntaxHighlighter
	Grammar plain = toPlainGrammar(g);
	
	SyntaxHighlighter hl = toSyntaxHighlighter(dfas, plain, startSymbol, name, file_extensions);
	toSublimeSyntaxFile(hl);
}