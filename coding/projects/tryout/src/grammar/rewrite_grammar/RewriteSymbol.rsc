module grammar::rewrite_grammar::RewriteSymbol

import Grammar;
import IO;
import symbols::IsTerminal;

tuple[Symbol, set[Symbol], set[Production]] rewriteSymbol_terminal(Symbol s) = <s, {s}, {}>;

tuple[Symbol, set[Symbol], set[Production]] rewriteSymbol_start(Symbol s) {
	<cur, new_syms, new_prods> = rewriteSymbol(s);
	new_sym = \start(cur);
	return <new_sym, new_syms + new_sym, new_prods>;
}
	
tuple[Symbol, set[Symbol], set[Production]] rewriteSymbol_opt(Symbol optional_sym) {
	<cur, new_syms, new_prods> = rewriteSymbol(optional_sym);
	new_sym = lex("<type(cur,())>_OPT");
	new_rules = {};
	new_rules += \prod(new_sym, [], {});
	new_rules += \prod(new_sym, [cur], {});
	return <new_sym, new_syms + new_sym, new_rules + new_prods>;
}

tuple[Symbol, set[Symbol], set[Production]] rewriteSymbol_iter(Symbol iter_sym) {
	<cur, new_syms, new_prods> = rewriteSymbol(iter_sym);
	new_sym = lex("<type(cur,())>_PLUS");
	new_rules = {};
	new_rules += \prod(new_sym, [cur, new_sym], {});
	new_rules += \prod(new_sym, [cur], {});
	return <new_sym, new_syms + new_sym, new_rules + new_prods>;
}

tuple[Symbol, set[Symbol], set[Production]] rewriteSymbol_iterstar(Symbol iter_sym) {
	<cur, new_syms, new_prods> = rewriteSymbol(iter_sym);
	new_sym = lex("<type(cur,())>_STAR");
	new_rules = {};
	new_rules += \prod(new_sym, [cur, new_sym], {});
	new_rules += \prod(new_sym, [], {});
	return <new_sym, new_syms + new_sym, new_rules + new_prods>;
}

tuple[Symbol, set[Symbol], set[Production]] rewriteSymbol_iterseps(Symbol iter_sym, list[Symbol] seps) {	
	<new_iter, new_syms, new_prods> = rewriteSymbol(iter_sym);
	new_seps = [rewriteSymbol(sep) | sep <- seps];
	str name = "<type(new_iter, ())>_" + ("" | it + "<type(tup[0], ())>" + "_"  | tup <- new_seps);
	new_sym = sort("<name>SEPS");
	new_sym_tail = sort("<name>SEPS_TAIL");
	new_rules = {};
	new_rules += \prod(new_sym, [new_iter, new_sym_tail], {});
	new_rules += \prod(new_sym_tail, [t[0] | t <- new_seps] + new_sym, {});
	new_rules += \prod(new_sym_tail, [], {});
	all_rules = new_prods + ({} | it + tup[2] | tup <- new_seps) + new_rules;
	all_syms = new_sym + ({} | it + tup[1] | tup <- new_seps) + new_syms;
	topsym = new_sym;
	return <topsym, all_syms, all_rules>;
	
}
 
tuple[Symbol, set[Symbol], set[Production]] rewriteSymbol_iterstarseps(Symbol iter_sym, list[Symbol] seps) {
	<new_iter, new_syms, new_prods> = rewriteSymbol(iter_sym);
	new_seps = [rewriteSymbol(sep) | sep <- seps];
	str name = "<type(new_iter, ())>_" + ("" | it + "<type(tup[0], ())>" + "_"  | tup <- new_seps);
	new_sym = sort("<name>STARSEPS");
	new_sym_tail = sort("<name>STARSEPS_TAIL");
	new_rules = {};
	new_rules += \prod(new_sym, [new_iter, new_sym_tail], {});
	new_rules += \prod(new_sym, [], {});
	new_rules += \prod(new_sym_tail, [t[0] | t <- new_seps] + new_sym, {});
	new_rules += \prod(new_sym_tail, [], {});
	all_rules = new_prods + ({} | it + tup[2] | tup <- new_seps) + new_rules;
	all_syms = new_sym + ({} | it + tup[1] | tup <- new_seps) + new_syms;
	topsym = new_sym;
	return <topsym, all_syms, all_rules>;
}

tuple[Symbol, set[Symbol], set[Production]] rewriteSymbol_alt(set[Symbol] alts) {
	new_syms = [rewriteSymbol(sym) | sym <- alts];
	name = ("" | it + "<type(tup[0], ())>" + "_"  | tup <- new_syms);
	new_sym = sort("<name>ALT");
	new_rules = {};
	for(tup <- new_syms) new_rules += \prod(new_sym, [tup[0]], {});
	return <new_sym, ({} | it + tup[1] | tup <- new_syms) + new_sym, new_rules + ({} | it + tup[2] | tup <- new_syms)>;
}

tuple[Symbol, set[Symbol], set[Production]] rewriteSymbol_seq(list[Symbol] syms) {
	new_syms = [rewriteSymbol(sym) | sym <- syms];
	name = ("" | it + "<type(tup[0], ())>" + "_"  | tup <- new_syms);
	new_sym = sort("<name>SEQ");
	new_rules = {};
	new_rules += \prod(new_sym, [tup[0] | tup <- new_syms], {});
	return <new_sym, ({} | it + tup[1] | tup <- new_syms) + new_sym, new_rules + ({} | it + tup[2] | tup <- new_syms)>;
}

tuple[Symbol, set[Symbol], set[Production]] rewriteSymbol(Symbol target) {
	//If the token is terminal (I.E. can be reduced to a "simple" regex, don't change it (E.G. [a-z]+)
	if (isTerminal(target)) return rewriteSymbol_terminal(target);
	switch(target) {
		case \empty(): 			return rewriteSymbol_terminal(target);
		case \layouts(_): 		return rewriteSymbol_terminal(target);
		case \sort(_): 			return rewriteSymbol_terminal(target);
		case \lex(_): 			return rewriteSymbol_terminal(target);
		case \keywords(_): 		return rewriteSymbol_terminal(target);
		case \lit(_): 			return rewriteSymbol_terminal(target);
		case \cilit(_): 		return rewriteSymbol_terminal(target);
		case \char-class(_): 	return rewriteSymbol_terminal(target);
		
		case \label(_, Symbol s): 	return rewriteSymbol(s);
		case \start(Symbol s): 		return rewriteSymbol_start(s);
		
		case \opt(Symbol opt_sym): 			return rewriteSymbol_opt(opt_sym);		
		case \iter(Symbol iter_sym): 		return rewriteSymbol_iter(iter_sym);
		case \iter-star(Symbol iter_sym): 	return rewriteSymbol_iterstar(iter_sym);
				
		case \iter-seps(Symbol s, list[Symbol] separators): 
			return rewriteSymbol_iterseps(s, separators);
		case \iter-star-seps(Symbol s, list[Symbol] separators): 
			return rewriteSymbol_iterstarseps(s, separators);
			
		case \alt(set[Symbol] alternatives): 	return rewriteSymbol_alt(alternatives);
		case \seq(list[Symbol] syms): 			return rewriteSymbol_seq(syms);
		
		//Do not change the conditions
		case \conditional(Symbol s, set[Condition] conditions): {
			<top_sym, new_syms, new_prods> = rewriteSymbol(s);
			new_top = \conditional(top_sym, conditions);
			return <new_top, new_syms + new_top, new_prods>;
		} default: throw error("Non_exhaustive pattern match rewriteSymbol: <target>");
	}
}	
