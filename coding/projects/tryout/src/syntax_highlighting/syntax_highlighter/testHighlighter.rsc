module syntax_highlighting::syntax_highlighter::testHighlighter

import syntax_highlighting::syntax_highlighter::SyntaxHighlighter;
import syntax_highlighting::SublimeText::ToSublimeSyntax;
import IO;

//Small test file for testing the SyntaxHighlighter datatype

void main() {
	id_regex = \str-regex("((?\<!)[a-z]) ([a-z]+) ((?!)[a-z])");
	id = \shvar("Id", id_regex);
	num_regex = \str-regex("((?\<!)[0-9]) ([a-z]+) ((?!)[0-9])");
	number = \shvar("Number", num_regex);
	Match mat_num, mat_id;
	Context con_num, con_id;
	con_id = 	\context-no-scope("Context-Id", {}, {});
	mat_num = 	\match(\str-regex("{{Num}}"), \scope("constant.numeric.integer.st"), \setact(["Context-Id"]));
	con_num = 	\context-no-scope("Context-Num", {}, {});
	mat_id = 	\match(\str-regex("{{Id}}"), \scope("keyword.controlflow.st"), \setact(["Context-Num"])); 
	con_id.matches += {mat_id};
	con_num.matches += {mat_num};
	con_main = 	\main-no-scope({}, {con_id, con_num});
	hl = \highlighter("Stat", {"st"}, {id, number}, ("Context_Id":con_id, "Context_Num":con_num, "main":con_main));
	toSublimeSyntaxFile(hl);
}