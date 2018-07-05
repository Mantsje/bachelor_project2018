module grammars::Statement

start syntax S 
	= Statement
	//| FuncHead
	;
	
syntax Statement
	= TypeDef "=" Number ";"
	//| TypeDef ";"
	;	

//syntax FuncHead
//	= TypeDef "(" ParamList ")" "{";
//
//syntax ParamList
//	=  {TypeDef ","}+ 
//	|
//	;

syntax TypeDef
	= Type Id
	;
	
lexical Id 
	= [a-z] !<< [a-z]+ !>> [a-z];

lexical Type 
	= @context="storage.type" "int" | "float";

lexical Number 
	= @context="constant.numeric.integer" [0-9] !<< [0-9]+ !>> [0-9]; 
