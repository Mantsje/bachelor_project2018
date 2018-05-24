module syntax_highlighting::SublimeText::SublimeRegex_grammar

import Prelude;
import syntax_highlighting::SublimeText::SublimeRegex;


/*TODO: Most likely useless in the future, seemed a good idea at some point. Less and less now */

layout Layout = [\ \r\t\n]*;

start syntax SublimeRegexNT
	= SubTopRegex
	| "?=" SubTopRegex 
	| "?\<=" SubTopRegex 
	| "?!" SubTopRegex 
	| "?\<!" SubTopRegex 
	;
	
syntax SubTopRegex
	= Regex
	| "^" Regex
	| Regex "$"
	;

syntax Regex
	= Union 
	| SimpleRegexNT
	;

syntax Union 
	= Regex "|" SimpleRegexNT
	;

syntax SimpleRegexNT
	= BasicRegexNT
	| Concatenation
	;

syntax Concatenation
	= Layout SimpleRegexNT Whitespace BasicRegexNT Layout
	;
	
lexical Whitespace = [\ \r\t\n] !<< [\ \r\t\n]+ !>> [\ \r\t\n];

syntax BasicRegexNT
	= ElementaryRegexNT
	| ElementaryRegexNT "*"
	| ElementaryRegexNT "+"
	| ElementaryRegexNT "?"
	;
	
syntax ElementaryRegexNT
	= "(" SublimeRegexNT ")"
	| Charclass
	| Token
	| Variable
	;

// Has no checking of whether it is a correct class, 
// just assumes the user and program does this
lexical Charclass
	= "[" Range+ "]"; 

lexical Range
	= Char "-" Char
	| Char
	;

lexical Variable 
	="{{" [a-zA-Z_0-9]+ "}}";
	
lexical Token 
	= Char !<< Char+ !>> Char;

lexical Char
	= "\\("  | "\\)" 
	| "\\["  | "\\]" 
	| "\\{"  | "\\}" 
	| "\\*"  | "\\+" 
	| "\\-"	 | "\\/" 
	| "\\?"  | "\\|" 
	| "\\^"  | "\\$" 
	| "\\!"  | "\\=" 
	| "\\\<" | "\\\>"
	| "\\ "  | "\\t"
	| "\\r"  | "\\n" 
	| "\\b" //Word brakes
	| ![\r\t\ \n*+?|^$!=\<\>\\\-\[\]{}()/]
	;
	
	
SublimeRegex toSublimeRegex((SublimeRegexNT)`<SubTopRegex s>`) = \sublime-regex(toSublimeRegex(s));
SublimeRegex toSublimeRegex((SublimeRegexNT)`?= <SubTopRegex s>`) = \look-ahead(toSublimeRegex(s));
SublimeRegex toSublimeRegex((SublimeRegexNT)`?\<= <SubTopRegex s>`) = \look-behind(toSublimeRegex(s));
SublimeRegex toSublimeRegex((SublimeRegexNT)`?! <SubTopRegex s>`) = \neg-look-ahead(toSublimeRegex(s));
SublimeRegex toSublimeRegex((SublimeRegexNT)`?\<! <SubTopRegex s>`) = \neg-look-behind(toSublimeRegex(s));

SubRegex toSublimeRegex((SubTopRegex)`<Regex r>`) = \sub-regex(toSublimeRegex(r));
SubRegex toSublimeRegex((SubTopRegex)`^ <Regex r>`) = \line-start(toSublimeRegex(r));
SubRegex toSublimeRegex((SubTopRegex)`<Regex r> $`) = \line-end(toSublimeRegex(r));

HeadRegex toSublimeRegex((Regex)`<Union u>`) = \head-union(toSublimeRegex(u));
HeadRegex toSublimeRegex((Regex)`<SimpleRegexNT s>`) = \head-simple(toSublimeRegex(s));

UnionRegex toSublimeRegex((Union)`<Regex t> | <SimpleRegexNT s>`) = \union(toSublimeRegex(t), toSublimeRegex(s));

SimpleRegex toSublimeRegex((SimpleRegexNT)`<BasicRegexNT b>`) = \simple-basic(toSublimeRegex(b));
SimpleRegex toSublimeRegex((SimpleRegexNT)`<Concatenation c>`) = \simple-concat(toSublimeRegex(c));

ConcatRegex toSublimeRegex((Concatenation)`<SimpleRegexNT s><Whitespace w2><BasicRegexNT b>`) = \concat(toSublimeRegex(s), toSublimeRegex(b));

BasicRegex toSublimeRegex((BasicRegexNT)`<ElementaryRegexNT e>`) = \basic-elementary(toSublimeRegex(e));
BasicRegex toSublimeRegex((BasicRegexNT)`<ElementaryRegexNT e> *`) = \star(toSublimeRegex(e));
BasicRegex toSublimeRegex((BasicRegexNT)`<ElementaryRegexNT e> +`) = \plus(toSublimeRegex(e));
BasicRegex toSublimeRegex((BasicRegexNT)`<ElementaryRegexNT e> ?`) = \optional(toSublimeRegex(e));

ElementaryRegex toSublimeRegex((ElementaryRegexNT)`( <SublimeRegexNT sh> )`) = \elem-bracket(toSublimeRegex(sh));
ElementaryRegex toSublimeRegex((ElementaryRegexNT)`<Charclass c>`) = \charclass(toSublimeRegex(c));
ElementaryRegex toSublimeRegex((ElementaryRegexNT)`<Token t>`) = \token(toSublimeRegex(t));
ElementaryRegex toSublimeRegex((ElementaryRegexNT)`<Variable v>`) = \variable(toSublimeRegex(v));
	
str toSublimeRegex(Variable v) = "<v>"[2..size("<v>")-2];
str toSublimeRegex(Token t) = "<t>";
str toSublimeRegex(Charclass c) = "<c>"[1..size("<c>")-1];