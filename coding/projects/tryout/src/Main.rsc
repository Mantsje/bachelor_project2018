module Main

import Grammar2Highlighter;
import Grammar;

//import lang::json::\syntax::JSON;
//import lang::javascript::saner::Syntax;
//import lang::c90::\syntax::C;
//import grammars::thesis::RascalExampleExp;
//import grammars::thesis::comments;
//import grammars::thesis::StringInterp;
//import grammars::thesis::Pico;
import grammars::A;

import IO;
import lang::rascal::format::Grammar;
import grammar::rewrite_grammar::ToPlainGrammar;
import grammar::strongly_regular_grammar::StronglyRegularGrammar;

void main() {
	//Grammar gr = grammar(#JSONText);
	//Grammar gr = grammar(#Source);
	//Grammar gr = grammar(#TranslationUnit);
	//Grammar gr = grammar(#Expression);
	//Grammar gr = grammar(#C);
	//Grammar gr = grammar(#String);
	//Grammar gr = grammar(#Program);
	Grammar gr = grammar(#S);

	//grammar2highlighter(gr, "JSON", {"json"});
	//grammar2highlighter(gr, "Javascript", {"js"});
	//grammar2highlighter(gr, "C", {"c", "h"});
	//grammar2highlighter(gr, "Expression", {"exp"});
	//grammar2highlighter(gr, "Comment", {"comm"});
	//grammar2highlighter(gr, "String", {"str"});
	//grammar2highlighter(gr, "Pico", {"pico"});
	grammar2highlighter(gr, "Example", {"ex"});

}

