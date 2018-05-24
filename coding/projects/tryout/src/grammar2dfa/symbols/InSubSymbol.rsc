module grammar2dfa::symbols::InSubSymbol

import Prelude;

/* just is some subsymbol of target in the target component 
 * so if A in component, then A+ should return true
 * Do distinction between the parts of target that are subsymbols and that arent later -> handled by rewriteForComponent
 */
bool inSubSymbol(Symbol target, set[Symbol] component) {
	switch(target) {
		case \sort(_):			return false;
		case \lex(_):			return false;
		case \keywords(_):		return false;
		case \lit(_): 			return false;
		case \cilit(_): 		return false;
		case \char-class(_): 	return false;
		
		case \opt(Symbol opt_sym): 			
			return opt_sym in component  || inSubSymbol(opt_sym, component);
		case \iter(Symbol iter_sym): 		
			return iter_sym in component || inSubSymbol(iter_sym, component);
		case \iter-star(Symbol iter_sym): 	
			return iter_sym in component || inSubSymbol(iter_sym, component);	
		case \iter-seps(Symbol s, list[Symbol] separators): 
			return (true | it || sym in component | sym <- separators+s);
		case \iter-star-seps(Symbol s, list[Symbol] separators): 
			return (true | it || sym in component | sym <- separators+s);			
		case \alt(set[Symbol] alternatives): 	
			return (true | it || sym in component | sym <- alternatives);
		case \seq(list[Symbol] syms): 			
			return (true | it || sym in component | sym <- syms);
		
		//TODO: fix this -> We just don't check the conditions for now
		case \conditional(Symbol s, set[Condition] conditions):
			return s in component || inSubSymbol(s, component);
		
		default: throw error("Non_exhaustive pattern match InSubSymbol: <target>");
	}
}	
