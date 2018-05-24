module syntax_highlighting::SublimeText::SublimeRegex

import grammar2dfa::automata::StateMachine;
import syntax_highlighting::SublimeText::SublimeRegex_grammar;

import ParseTree;

/* Contains functionality for generating and rewriting regexes in Sublime-Text syntax files
 * Porbably deprecated in the future since the grammar isn very useful/accurate
 */

data SublimeRegex 
	= \sublime-regex(SubRegex subregex)
	| \look-ahead(SubRegex subregex)
	| \look-behind(SubRegex subregex)
	| \neg-look-ahead(SubRegex subregex)
	| \neg-look-behind(SubRegex subregex)
	;

data SubRegex
	= \sub-regex(HeadRegex hregex)
	| \line-start(HeadRegex hregex)
	| \line-end(HeadRegex hregex)	
	;

data HeadRegex
	= \head-union(UnionRegex uregex)
	| \head-simple(SimpleRegex sregex)
	;

data UnionRegex
	= \union(HeadRegex hhead, SimpleRegex stail)
	;

data SimpleRegex
	= \simple-basic(BasicRegex bregex)
	| \simple-concat(ConcatRegex cregex)
	;

data ConcatRegex
	= \concat(SimpleRegex shead, BasicRegex btail)
	;
	
data BasicRegex
	= \star(ElementaryRegex eregex)
	| \plus(ElementaryRegex eregex)
	| \optional(ElementaryRegex eregex)
	| \basic-elementary(ElementaryRegex eregex)
	;

data ElementaryRegex
	= \elem-bracket(SublimeRegex sublimeRegex)
	| \charclass(str str_repres_no_bracket)
	| \token(str tok)
	| \variable(str str_repres_no_bracket)
	;
	
str sublimeRegexToString(ElementaryRegex regex) {
	str out = "";
	switch(regex) {
		case \elem-bracket(SublimeRegex reg): {
			return "(" + sublimeRegexToString(reg) + ")";
		} case \charclass(str ranges): {
			return "[<ranges>]";
		} case \token(str tok): {
			return "<tok>";
		} case \variable(str name): {
			return "{{<name>}}";		
		}
	}
}

str sublimeRegexToString(BasicRegex regex) {
	str out = "";
	switch(regex) {
		case \star(ElementaryRegex sreg): {
			out = sublimeRegexToString(sreg) + "*";
		} case \plus(ElementaryRegex preg): {
			out = sublimeRegexToString(preg) + "+";
		} case \optional(ElementaryRegex oreg): {
			out = sublimeRegexToString(oreg) + "?";
		} case \basic-elementary(ElementaryRegex breg): {
			return sublimeRegexToString(breg);		
		}
	}
	return "<out>";
}

str sublimeRegexToString(ConcatRegex regex) {
	str out = "";
	switch(regex) {
		case \concat(SimpleRegex shead, BasicRegex btail): {
			out = sublimeRegexToString(shead) + " " + sublimeRegexToString(btail);
		} 
	}
	return "<out>";
}

str sublimeRegexToString(SimpleRegex regex) {
	str out = "";
	switch(regex) {
		case \simple-basic(BasicRegex breg): {
			return sublimeRegexToString(breg);
		} case \simple-concat(ConcatRegex creg): {
			return sublimeRegexToString(creg);
		}
	}
}

str sublimeRegexToString(UnionRegex regex) {
	str out = "";
	switch(regex) {
		case \union(HeadRegex hreg, SimpleRegex sreg): {
			out = sublimeRegexToString(hreg) + "|" + sublimeRegexToString(sreg);
		} 
	}
	return "<out>";
}

str sublimeRegexToString(HeadRegex regex) {
	str out = "";
	switch(regex) {
		case \head-union(UnionRegex ureg): {
			return sublimeRegexToString(ureg);
		} case \head-simple(SimpleRegex sreg): {
			return sublimeRegexToString(sreg);
		}
	}
}

str sublimeRegexToString(SubRegex regex) {
	str out = "";
	switch(regex) {
		case \sub-regex(HeadRegex hreg): {
			return sublimeRegexToString(hreg);
		} case \line-start(HeadRegex hreg): {
			out = "^" + sublimeRegexToString(hreg);
		} case \line-end(HeadRegex hreg): {
			out = sublimeRegexToString(hreg) + "$";
		}
	}
	return "<out>";
}

str sublimeRegexToString(SublimeRegex regex) {
	str out = "";
	switch(regex) {
		case \sublime-regex(SubRegex subreg): {
			return sublimeRegexToString(subreg);
		} case \look-ahead(SubRegex subreg): {
			out = "?=" + sublimeRegexToString(subreg);
		} case \look-behind(SubRegex subreg): {
			out = "?\<=" + sublimeRegexToString(subreg);
		} case \neg-look-ahead(SubRegex subreg): {
			out = "?!" + sublimeRegexToString(subreg);		
		} case \neg-look-behind(SubRegex subreg): {
			out = "?\<!" + sublimeRegexToString(subreg);		
		}
	}
	return "(<out>)";
}
	
SublimeRegex stringToSublimeRegex(str target) {
	ptree = parse(#SublimeRegexNT, target);
	return toSublimeRegex(ptree);
}