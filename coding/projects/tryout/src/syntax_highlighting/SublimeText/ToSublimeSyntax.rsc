module syntax_highlighting::SublimeText::ToSublimeSyntax

import IO;
import syntax_highlighting::syntax_highlighter::SyntaxHighlighter;
import Prelude;

/* Rewrite a SyntaxHighlighter instance to a .sublime-syntax file. Call top level function at the bottom */

str tabs(int tablevel) 
	= ("" | it + "  " | i <- [0..tablevel]);

str ln(str text, int tablevel) 
	= tabs(tablevel) + text + "\n";

str emptyline() = "\n";

str toSublimeString(SHRegex regex, int tablevel) {
	strfile = "";
	switch(regex) {
		case \str-regex(str regex_str): strfile += regex_str;
		default: throw error("non-exhaustive regex found! <regex>");
	}
	return strfile;
}

str toSublimeString(SHvar var, int tablevel) 
	= ln("<var.name>: \'<toSublimeString(var.regex, 0)>\'", tablevel);


str toSublimeString(Action action, int tablevel) {
	strfile = "";
	switch(action) {
		case \push(list[str] contexts): {
			s = ("" | it + "<c>, " | c <- contexts);
			strfile += ln("push: [<s[..size(s) - 2]>]", tablevel);
		} case \setact(list[str] contexts): {
			s = ("" | it + "<c>, " | c <- contexts);
			strfile += ln("set: [<s[..size(s) - 2]>]", tablevel);
		} case \pop(): {
			strfile += ln("pop: true", tablevel);
		} case \noact(): {
			return strfile;
		} default: throw error("Non-Exhaustive pattern match in Action");
	}
	return strfile;
}

str toSublimeString(Match mtch, int tablevel) {
	strfile = "";
	switch(mtch) {
		case \match(SHRegex regex, Scope scope, Action action): {
			strfile += ln("- match: \'<toSublimeString(regex, 0)>\'", tablevel);
			strfile += toSublimeString(scope, tablevel + 1);
			strfile += toSublimeString(action, tablevel + 1);	
		} default: throw error("Non-Exhaustive pattern match in Match");
	}
	return strfile;
}

str toSublimeString(Scope scp, int tablevel) {
	strfile = "";
	switch(scp) {
		case \scope(str name): {
			strfile += ln("scope: <name>", tablevel);
		} case \meta-scope(str name): {
			strfile += ln("- meta_scope: <name>", tablevel);
		} case \null(): {
			strfile = "";
		} default: throw error("Non-Exhaustive pattern match in Scope");
	}
	return strfile;
}

str contextBody(str name, Context con, int tablevel, bool includePrototype=true) {
	strfile = "";
	strfile += ln("<name>:", tablevel);
	tablevel += 1;
	if(!includePrototype) strfile += ln("- meta_include_prototype: false",tablevel);
	strfile += toSublimeString(con.scope, tablevel);
	for (i <- con.includes) strfile += ln("- include: <i.name>", tablevel);
	for (m <- con.matches) strfile += toSublimeString(m, tablevel);
	strfile += emptyline();
	return strfile;
}

str toSublimeString(Context cont, int tablevel) {
	strfile = "";
	switch(cont) {
		case \context(str name, Scope scope, set[Match] matches, set[Context] includes): {
			strfile += contextBody(name, cont, tablevel, includePrototype=cont.includePrototype);
		} case \main(Scope scope, set[Match] matches, set[Context] includes): {
			strfile += contextBody("main", cont, tablevel);
		} case \prototype(Scope scope, set[Match] matches, set[Context] includes): {
			strfile += contextBody("prototype", cont, tablevel);
		} default: throw error("Non-Exhaustive pattern match in Context");
	}
	strfile += emptyline();
	return strfile;
}

str highlightertoSublimeString(SyntaxHighlighter syn, int tablevel) {
	strfile = "";
	switch(syn) {
		case \highlighter(str name, set[str] extensions, set[SHvar] vars, map[str, Context] contexts): {
			strfile += ln("%YAML 1.2", tablevel);
			strfile += ln("---", tablevel);
			strfile += emptyline();
			strfile += ln("name: <name>", tablevel);
			exlst = ("" | it + "<ex>, " | ex <- extensions);
			strfile += ln("file_extensions: [<exlst[..size(exlst) - 2]>]", tablevel);
			strfile += ln("scope: source.<takeOneFrom(extensions)[0]>", tablevel);
			strfile += emptyline();
			if(!isEmpty(vars)) {
				strfile += ln("variables:", tablevel);
				for(var <- vars) strfile += toSublimeString(var, tablevel + 1);
				strfile += emptyline();
			}
			strfile += ln("contexts:", tablevel);
			for(cont <- sort({c | c <- contexts})) strfile += toSublimeString(contexts[cont], tablevel + 1);	
		} default: throw error("Non-Exhaustive pattern match in SyntaxHighlighter");
	}
	return strfile;
}

void toSublimeSyntaxFile(SyntaxHighlighter syn) {
	writeFile(|project://tryout/highlighter/<syn.name>.sublime-syntax|, highlightertoSublimeString(syn, 0));
}