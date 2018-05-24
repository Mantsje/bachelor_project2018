module grammar2dfa::automata::StateMap

import Grammar;

import grammar2dfa::automata::StateMachine;
import grammar2dfa::symbols::SymbolToString;

alias StateMap	= map[Token, tuple[State, State]];


/* TODO: fix the following: Has all cases for now, since it helps finding bugs and errors because of (yet) unknown symbols and how to deal with those
 * TODO: look at what to doo with layouts again
*/
tuple[State, State] mapState(Symbol s) {
	tuple[State, State] out;
	symname = symbolToString(s);
	switch(s) {
		case \layouts(_):			throw error("Reached onon reachable case");
		case \empty():				throw error("Reached non reachable case");
		case \lit(_): 				out = <"start_<symname>", "final_<symname>">; 
		case \cilit(_): 			out = <"start_<symname>", "final_<symname>">; 
		case \char-class(_):		out = <"start_<symname>", "final_<symname>">; 
		case \sort(_): 				out = <"start_<symname>", "final_<symname>">;
		case \lex(_): 				out = <"start_<symname>", "final_<symname>">;
		case \keywords(_): 			out = <"start_<symname>", "final_<symname>">;
		case \alt(_): 				out = <"start_<symname>", "final_<symname>">;
		case \iter(_):				out = <"start_<symname>", "final_<symname>">;
		case \iter-star(_): 		out = <"start_<symname>", "final_<symname>">;
		case \iter-seps(_,_):		out = <"start_<symname>", "final_<symname>">;
		case \iter-star-seps(_, _): out = <"start_<symname>", "final_<symname>">;
		case \seq(_): 				out = <"start_<symname>", "final_<symname>">;
		case \conditional(_, _):	out = <"start_<symname>", "final_<symname>">;
		case \opt(_): 				out = <"start_<symname>", "final_<symname>">;
		default: throw error("Non-Exhaustive pattern-match in mapState: <s>");
	}
	return out;
}

StateMap generateStateMap(set[Symbol] symbols)
	 = ( s:mapState(s) | s <- symbols);
