module syntax_highlighting::regexes::Main

import Grammar;
import String;

import syntax_highlighting::regexes::ToRegex;
import syntax_highlighting::regexes::Prod2Regex;

import syntax_highlighting::syntax_highlighter::SyntaxHighlighter;


SHRegex prod2regex(Production p, map[Symbol, str] regmap) {
	SHRegex regex = stringToSHRegex("(<prod2strregex(p, regmap)>)");
	return regex;
}

SHRegex toRegex(Symbol s, map[Symbol, str] regmap) {
	str str_regex = symbolToRegex(s, regmap);
	SHRegex regex = stringToSHRegex("(<str_regex>)");
	return regex;
}

SHRegex lookaheadRegex(\str-regex(str reg)) {
	SHRegex regex = stringToSHRegex("(?=(<reg>))");
	return regex;
}
  
SHRegex lookaheadRegex(Symbol s, map[Symbol, str] regmap) {
	str str_regex = symbolToRegex(s, regmap);
	SHRegex regex = stringToSHRegex("(?=(<str_regex>))");
	return regex;
}

SHRegex negLookaheadRegexAlts(set[Symbol] syms, map[Symbol, str] regmap) {
	set[str] str_regexes = {symbolToRegex(s, regmap) | s <- syms};
	str str_regex = ("" | it + str_regex + "|" | str_regex <- str_regexes);
	SHRegex regex = stringToSHRegex("(?!(<str_regex[..size(str_regex)-1]>))");
	return regex;
}

SHRegex negLookaheadRegexAlts(set[SHRegex] regs) {
	set[str] str_regexes = {reg.regex | reg <- regs};
	str str_regex = ("" | it + str_regex + "|" | str_regex <- str_regexes);
	SHRegex regex = stringToSHRegex("(?!(<str_regex[..size(str_regex)-1]>))");
	return regex;
}

SHRegex lookaheadRegexAlts(set[Symbol] syms, map[Symbol, str] regmap) {
	set[str] str_regexes = {symbolToRegex(s, regmap) | s <- syms};
	str str_regex = ("" | it + str_regex + "|" | str_regex <- str_regexes);
	SHRegex regex = stringToSHRegex("(?=(<str_regex[..size(str_regex)-1]>))");
	return regex;
}

tuple[SHRegex, SHRegex] conditionRegex(Condition con, map[Symbol, str] regmap) {
	<pref, post> = conditionToRegex(con, regmap);
	return <stringToSHRegex("(<pref>)"), stringToSHRegex("(<post>)")>;
}