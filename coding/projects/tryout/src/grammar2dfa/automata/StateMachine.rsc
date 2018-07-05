module grammar2dfa::automata::StateMachine

import symbols::SymbolToString;
import Prelude;

/* *********** *********** defs *********** *********** */

alias State = str;
alias Token = Symbol;
alias DeltaFunction = rel[State from, Token token, State to];
alias Transition = tuple[State from, Token token, State to];

data StateMachine
	= \sm-dfa(DeltaFunction transitions, State startState, set[State] finalStates)
	| \sm-nfa(DeltaFunction transitions, State startState, set[State] finalStates)
	;

/* *********** *********** end defs *********** *********** */


set[Token] getAlphabet(StateMachine fa)
	= {t[1] | t <- fa.transitions};
	
set[Token] getAlphabetOfState(StateMachine fa, State s)
	= {t[0] | t <- fa.transitions[s]};

set[Transition] getTransitionsOfState(StateMachine fa, State s)
	= {<s, tup[0], tup[1]> | tup <- fa.transitions[s]};

set[State] getStates(StateMachine fa)
	= ({} | it + t[0] + t[2] | t <- fa.transitions) + fa.startState + fa.finalStates;
	
	
/* *********** *********** printing *********** *********** */

str tokenToString(Token tok) = symbolToString(tok);

void printStateMachine(StateMachine fa) {
	println("start: <fa.startState>");
	println("final: <fa.finalStates>");
	for(trans <- fa.transitions) println("<<trans[0], tokenToString(trans[1]), trans[2]>>");
	println();
}

void printStateMachineForGenerator(StateMachine fa) {
	set[tuple[str, str]] illegal = {
									//<"(", "P_OP">, 
									//<")", "P_CL">, 
									//<"[", "B_OP">,
									//<"]", "B_CL">,
									//<"{", "C_OP">,
									//<"}", "C_CL">,
									//<"+", "PLUS">, 
									//<"-", "DASH">, 
									//<"*", "STAR">, 
									<";", "SEMI">,
									<"\>", "GT">,
									//<"\<", "LT">,
									<",", "COMMA">,
									//<".", "DOT">, 
									<"=", "EQUAL">, 
									//<"?", "QMARK">, 
									//<"!", "EXCL">, 
									//<"/", "SLASH">,
									//<"\\", "BSLASH">, 
									<"\"", "DQUOTE">,
									<"\'", "SQUOTE">,
									<":", "COLON">,
									//<"|", "VBAR">, 
									//<"`", "BTICK">,
									//<"_", "UNSCR">, 
									<" ", "_">
									};
	println("#states");
	for (s <- getStates(fa)) {
		for(il <- illegal) s = replaceAll(s, il[0], il[1]);
		println(s);
	}
	println("#initial");
	str init = fa.startState;
	for(il <- illegal) init = replaceAll(init, il[0], il[1]);
	println(init);
	println("#accepting");
	for (s <- fa.finalStates) {
		for(il <- illegal) s = replaceAll(s, il[0], il[1]);
		println(s);
	}
	println("#alphabet");
	for (tok <- getAlphabet(fa)) {
		s = tokenToString(tok);
		for(il <- illegal) s = replaceAll(s, il[0], il[1]);
		println(s);
	}
	println("#transitions");
	for (t <- fa.transitions) {
		<s0, tok1, s2> = t;
		s1 = tokenToString(tok1);
		for(il <- illegal) {
			s0 = replaceAll(s0, il[0], il[1]);
			s1 = replaceAll(s1, il[0], il[1]);
			s2 = replaceAll(s2, il[0], il[1]);
		}
		println("<s0>:<s1>\><s2>");
	}
	println();
}

/* *********** *********** end printing *********** *********** */