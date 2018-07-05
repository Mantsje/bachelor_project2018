module grammars::thesis::comments

import Grammar;

start syntax C
	= @Context="comment.block" Comment
	;

lexical Comment
	= "/*" (ComChar | Comment)* "*/"
	;
	
lexical ComChar
	= ![*/]
	| [*] !>> [/]
	| [/] !>> [*]
	;