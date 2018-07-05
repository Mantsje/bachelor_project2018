module grammars::A

start syntax S = A;

lexical A = (B | D)+;

lexical B 
	= @Context="keyword.control.flow" "b"
	| @Context="null keyword.control.flow" D "b"
	;

lexical D 
	= @Context="storage.type" "d"
	| @Context="storage.type null" "d" B
	;