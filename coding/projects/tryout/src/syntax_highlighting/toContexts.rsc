module syntax_highlighting::toContexts

import Prelude;

import grammar2dfa::automata::StateMachine;
import grammar2dfa::symbols::ToRegex;
import grammar2dfa::symbols::SymbolToString;
import syntax_highlighting::syntax_highlighter::SyntaxHighlighter;

/* No variables yet
 * One context per state
 * "just" match the expected symbol
 * set next state
 * if next_state is final and has no outgoing transitions pop instead of set
 * else: make some lookahead decision
 */
 
 
 /* checks wheter a state is final and has no outgoing transitions*/
 bool isNextStateFinalSink(StateMachine fa, State s)
 	= s in fa.finalStates && size(fa.transitions[s]) == 0;
 
 
 /* Maps a map of dfas to contexts for the syntax highlighter 
  * It should:
  * 	1. For transitions with non-terminals as token, find the first terminal symbol that could arise from this rule
  *		  then create a lookahead regex that checks whether this symbol is found. Then continue parsing this NT 
  				- This process is quite complicated and yet to be implemented here
  *		2. For transitions with terminals as token add a Match for this token and set the context to the next state
  *		3. It should rewrite all the instances of Symbol to either a readable name, or create a valid YAML-like regex
  				- Also yet to be done
  *
  */
 set[Context] toContexts(map[Symbol, StateMachine] dfas, Symbol startSymbol) {
 	map[tuple[Symbol, State], Context] contexts = ();
	for (dfa_name <- dfas) {	
		cur_dfa = dfas[dfa_name];
		set[State] states = getStates(cur_dfa);
		for (s <- states) contexts += (<dfa_name, s>:\context-no-scope("<symbolToString(dfa_name)>_<s>", {}, {}));
	}
	set[tuple[Symbol, State]] reachable = {};
	for (dfa_sym <- dfas) {
		dfa = dfas[dfa_sym];
		for (tr:<cur_state, sym_tok, next_state> <- dfa.transitions) {
			next_con = contexts[<dfa_sym, next_state>];
			str str_regex = symbolToRegex(sym_tok);
			SHRegex regex = \str-regex(str_regex);
			if (isNextStateFinalSink(dfa, next_state)) {
				contexts[<dfa_sym, cur_state>].matches += {\match-no-scope(regex, \pop())};
				contexts -= (<dfa_sym, next_state>:contexts[<dfa_sym, next_state>]);
			} else if (next_state in dfa.finalStates) {
				contexts[<dfa_sym, cur_state>].matches += {\match-no-scope(\str-regex(""), \pop())};
				contexts[<dfa_sym, cur_state>].matches += {\match-no-scope(regex, \setact([next_con]))};
				reachable += <dfa_sym, next_state>;
			} else {
				contexts[<dfa_sym, cur_state>].matches += {\match-no-scope(regex, \setact([next_con]))};
				reachable += <dfa_sym, next_state>;
			}
		}
	}
	println(size(contexts));
	return {contexts[tup] | tup <- contexts};
 }