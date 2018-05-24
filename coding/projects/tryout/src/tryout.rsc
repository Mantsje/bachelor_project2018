module tryout

import Prelude;

import grammar2dfa::Grammar2Automaton;
import grammar2dfa::automata::StateMachine;
import grammar2dfa::symbols::SymbolSet;

import syntax_highlighting::toContexts;
import syntax_highlighting::syntax_highlighter::SyntaxHighlighter;
import syntax_highlighting::SublimeText::ToSublimeSyntax;


//import grammars::A;
import grammars::Statement;
//import grammars::Function;
//import lang::json::\syntax::JSON;
//import lang::java::\syntax::Java15;
//import lang::c90::\syntax::C;

void main() {
	//Grammar gr = grammar(#A);
	Grammar gr = grammar(#S);
	//Grammar gr = grammar(#Function);
	//Grammar gr = grammar(#JSONText);
	//Grammar gr = grammar(#CompilationUnit);
	//Grammar gr = grammar(#TranslationUnit);

	<startSymbol, rules, comps> = preprocessGrammar(gr);
	map[Symbol, StateMachine] dfas = generateDFAPerSymbol(gr);
	set[Context] contexts = toContexts(dfas, startSymbol);
	toSublimeSyntaxFile(\highlighter("Test", {"test"}, {}, contexts));
	
	//StateMachine final_dfa = generateSuperDFA(gr);
	//printStateMachineForGenerator(final_dfa);
	
}