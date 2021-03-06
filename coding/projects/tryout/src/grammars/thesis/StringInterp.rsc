module grammars::thesis::StringInterp

import Grammar;

start syntax String
	= StringLiteral
	;

lexical StringLiteral
	= @Context="string.quoted.double" "\"" StringBody "\""
	;

lexical StringBody
	= @Context="string.quoted.double" (![\"\<\>]|"\\\<"|"\\\>"|"\\\"")+
	| @Context="string.quoted.double null null null string.quoted.double" StringBody "\<" Interp "\>" StringBody
	;

lexical Interp
	= ![\>]+
	;