module TerminalRunCode

import Grammar;
import IO;
import lang::rascal::format::Grammar;
import grammar::rewrite_grammar::ToPlainGrammar;
import grammar::strongly_regular_grammar::StronglyRegularGrammar;
import graph::Grammar2Graph;
import grammar2dfa::automata::StateMachine;
import grammar2dfa::automata::NFA2DFA;
import grammar2dfa::ComponentMachines;
import Grammar2Highlighter;

//import grammars::thesis::RascalExampleExp;
//import grammars::thesis::comments;
import grammars::thesis::StringInterp;
//import grammars::thesis::Pico;

//Grammar gr = grammar(#Expression);
//Grammar gr = grammar(#C);
Grammar gr = grammar(#String);
//Grammar gr = grammar(#Program);


plain = toPlainGrammar(gr);
reg = toStronglyRegularGrammar(gr);
reg_comps = grammar2strConnectedComponents(reg);
nfas = generateComponentNFAs(reg, reg_comps);
dfas = (sym:NFA2DFA(nfas[sym]) | sym <- nfas);
condfas = getConflictlessComponentMachines(reg);


printStateMachineForGenerator(nfas[lex("StringLiteral")]);
printStateMachine(nfas[lex("StringLiteral")]);
printStateMachineForGenerator(dfas[lex("StringLiteral")]);