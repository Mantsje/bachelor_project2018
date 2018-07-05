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
		case \lit(_): 				out = <"<symname>_start", "<symname>_final">; 
		case \cilit(_): 			out = <"<symname>_start", "<symname>_final">; 
		case \char-class(_):		out = <"<symname>_start", "<symname>_final">;
		case \sort(_): 				out = <"<symname>_start", "<symname>_final">;
		case \lex(_): 				out = <"<symname>_start", "<symname>_final">;
		case \keywords(_): 			out = <"<symname>_start", "<symname>_final">;
		case \alt(_): 				out = <"<symname>_start", "<symname>_final">;
		case \iter(_):				out = <"<symname>_start", "<symname>_final">;
		case \iter-star(_): 		out = <"<symname>_start", "<symname>_final">;
		case \iter-seps(_,_):		out = <"<symname>_start", "<symname>_final">;
		case \iter-star-seps(_, _): out = <"<symname>_start", "<symname>_final">;
		case \seq(_): 				out = <"<symname>_start", "<symname>_final">;
		case \conditional(_, _):	out = <"<symname>_start", "<symname>_final">;
		case \opt(_): 				out = <"<symname>_start", "<symname>_final">;
		default: throw error("Non-Exhaustive pattern-match in mapState: <s>");
	}
	return out;
}

StateMap generateStateMap(set[Symbol] symbols)
	 = ( s:mapState(s) | s <- symbols);
