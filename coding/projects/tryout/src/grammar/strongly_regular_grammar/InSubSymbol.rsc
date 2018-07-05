module grammar::strongly_regular_grammar::InSubSymbol

import Prelude;

tuple[bool, Symbol] inSubSymHelper(Symbol target, Symbol sub, set[Symbol] component) { 
	<inhere, sym> = isSubSymbolInComponent(sub, component);
	if (inhere) return <inhere, sym>;
	return <target in component, target>;
}

tuple[bool, Symbol] inSubSymHelper(Symbol target, set[Symbol] sublist, set[Symbol] component) { 
	for(s <- sublist) {
		<inhere, sym> = isSubSymbolInComponent(s, component);
		if (inhere) return <inhere, sym>;
	}
	return <target in component, target>;
}

tuple[bool, Symbol] inSubSymHelper(Symbol target, Symbol sub, set[Symbol] sublist, set[Symbol] component) { 
	<inhere, sym> = inSubSymHelper(target, sub, component);
	if (inhere) return <inhere, sym>;
	<inhere, sym> = inSubSymHelper(target, sublist, component);
	if (inhere) return <inhere, sym>;
	return <target in component, target>;
}

/* just is some subsymbol of target in the target component 
 * so if A in component, then A+ should return true
 * together with the symbol it matched
 */
tuple[bool, Symbol] isSubSymbolInComponent(Symbol target, set[Symbol] component) {
	switch(target) {
		case \sort(_):				return <target in component, target>;
		case \lex(_):				return <target in component, target>;
		case \keywords(_):			return <target in component, target>;
		case \lit(_): 				return <target in component, target>;
		case \cilit(_): 			return <target in component, target>;
		case \char-class(_): 		return <target in component, target>;
		case \layouts(_): 			return <target in component, target>;
		case \empty(): 				return <false, target>;
		case \label(_, Symbol s): 	return isSubSymbolInComponent(s, component);
		
		case \opt(Symbol opt_sym): 			return inSubSymHelper(target, opt_sym, component);
		case \iter(Symbol iter_sym): 		return inSubSymHelper(target, iter_sym, component); 
		case \iter-star(Symbol iter_sym): 	return inSubSymHelper(target, iter_sym, component);
		
		case \iter-seps(Symbol s, list[Symbol] separators): 		return inSubSymHelper(target, s, toSet(separators), component);
		case \iter-star-seps(Symbol s, list[Symbol] separators): 	return inSubSymHelper(target, s, toSet(separators), component);
		
		case \alt(set[Symbol] alternatives):return inSubSymHelper(target, alternatives, component);
		case \seq(list[Symbol] syms):  		return inSubSymHelper(target, toSet(syms), component);
			
		//TODO: fix this -> We just don't check the conditions for now
		case \conditional(Symbol s, set[Condition] conditions):
			return inSubSymHelper(target, s, component);
		
		default: throw error("Non_exhaustive pattern match InSubSymbol: <target>");
	}
}	
