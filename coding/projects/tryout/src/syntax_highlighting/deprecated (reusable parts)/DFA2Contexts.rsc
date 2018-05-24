module syntax_highlighting::temp_deprecated::DFA2Contexts

import Prelude;

import grammar2dfa::automata::StateMachine;
import grammar2dfa::symbols::IsTerminal;

import grammar2dfa::symbols::ToRegex;
import grammar2dfa::symbols::SymbolToString;

import syntax_highlighting::SublimeText::ToSublimeSyntax;
import syntax_highlighting::syntax_highlighter::SyntaxHighlighter;

//Also Sublime oriented file based on getContexts. WE can extract this by giving an extra parameter to some construct regex function. to state which type

bool isStartFinalTransition(Transition tr, StateMachine fa) {
	return (tr[0] == fa.startState && tr[2] in fa.finalStates) 
		|| (tr[0] in fa.finalStates && tr[2] in fa.finalStates);
}

bool canBeReduced(StateMachine fa) {
	return (true | it && tr[0] == fa.startState && tr[2] in fa.finalStates | tr <- fa.transitions);
}

bool hasOnlyVariableTransitions(StateMachine fa, map[Symbol, bool] isVar) {
	return (true | it && isVar[tr[1]] | tr <- fa.transitions);
}

/* Tries to make SHvars from simple single-transition state machinces
 * First: for all machines that have 1 transition
 * if the token ([1]) does not occur in the inverted symbolmap (mapsym) set its isVar value
 * This means that the token does not have a custom dfa and the token is therefore terminal 
 * 
 * For every machine that is not isVar
 * If it is single transition (meaning that it is some "higher level dfa" that has a single transition consisting of a dfa that isVar)
 * Just to make sure: Check if the token of this transition isVar
 * make the actual shvar datatype, remove the two old dfas and add 1 new one consuming only the shvar
 *
 * return the new set of dfas and the SHvars
 */
tuple[map[Symbol, StateMachine], map[Symbol, SHvar]] getVariables(map[Symbol, StateMachine] dfas) {
	map[Symbol, SHvar] vars = ();
	map[Symbol, bool] isVar = (sym:false | sym <- dfas);
	for (sym <- dfas, isTerminal(sym)) {
		isVar[sym] = true;
	}
	map[Symbol, StateMachine] dfasToGo = ();
	map[Symbol, StateMachine] dfasToCome = ();
	for (dfa_sym <- isVar, !isVar[dfa_sym], canBeReduced(dfas[dfa_sym])) {
		dfa = dfas[dfa_sym];
		if (hasOnlyVariableTransitions(dfa, isVar)) {
			DeltaFunction trans = dfa.transitions; 
			fullRegex = "";
			for (tr <- trans) {
				tuple[str, str, str] tr_str = <tr[0], tokenToString(tr[1]), tr[2]>;
				useless_dfa = dfas[tr[1]];
				terminal_regex = symbolToRegex(tr[1]);
				//println("regex: <terminal_regex>");
				fullRegex += terminal_regex + " | ";
				dfasToGo += (tr[1]:dfas[tr[1]]);
			}
			fullRegex = fullRegex[..size(fullRegex) - 3];
				
			SHRegex regex = stringToSHRegex(fullRegex);
			varName = symbolToString(dfa_sym);
			varSymbol = \lit("{{<varName>}}");
			vars += (varSymbol:\shvar(varName, regex));
			dfasToGo += (dfa_sym:dfa);
			finalState = takeOneFrom(dfa.finalStates)[0];
			StateMachine new_dfa = \sm-dfa({<dfa.startState, varSymbol, finalState>}, dfa.startState, {finalState});
			dfasToCome += (dfa_sym:new_dfa);
		}
	}
	dfas -= dfasToGo;
	dfas += dfasToCome;
	return <dfas, vars>;
}


//TODO: No scopes ever, change that
/* First for every state in every dfa create an empty context
 * Then for every transition 
 * Create a match that either sets the context to the next state, or replaces the 
 * current context with the next state and then pushes the start state of another machine to be parsed
 */
set[Context] getContextsPerDFA(map[Symbol, StateMachine] dfas, map[Symbol, SHvar] vars) {
	map[tuple[Symbol, State], Context] contexts = ();
	
	for (dfa_name <- dfas) {	
		cur_dfa = dfas[dfa_name];
		set[State] states = getStates(cur_dfa);
		for (s <- states) contexts += (<dfa_name, s>:\context-no-scope("<dfa_name>_<s>", {}, {}));
	}
	println(size(contexts));
	for (dfa_name <- dfas) {	
		cur_dfa = dfas[dfa_name];
		for (tr <- cur_dfa.transitions) {
			next_con = contexts[<dfa_name, tr[2]>];
			tr_str = <tr[0], tokenToString(tr[1]), tr[2]>;
			if(tr[1] in dfas) {
				str str_regex = symbolToRegex(tr[1]);
				SHRegex regex = \str-regex("NT_" + str_regex);
				contexts[<dfa_name, tr[0]>].matches += {\match-no-scope(regex, \setact([next_con]))};
			} else {
				//means its a var
				contexts[<dfa_name, tr[0]>].matches += {\match-no-scope(vars[tr[1]].regex, \setact([next_con]))};
			}
		}
	}
	return {contexts[c] | c <- contexts};
}


void toSyntaxHighlighter(Symbol startsym, map[Symbol, StateMachine] dfas) {
	println("num dfas: <size(dfas)>");
	<dfas, variables> = getVariables(dfas);
	//for(var <- variables) println("<var> : <variables[var].name>, <SHRegexToString(variables[var].regex)>");
	//for(dfa <- dfas) println("<dfa> : <dfas[dfa]>");
	set[Context] contexts = getContextsPerDFA(dfas, variables);
	println("num states in all dfas: <(0 | it + size(getStates(dfas[d])) | d <- dfas)>");
	println("num trans in all dfas: <size([t | d <- dfas, t <- dfas[d].transitions])>");
	println("num dfas: <size(dfas)>");
	println("num contexts: <size(contexts)>");
	toSublimeSyntaxFile(\highlighter("Test", {"test"}, {variables[c] | c <- variables}, contexts));
}
