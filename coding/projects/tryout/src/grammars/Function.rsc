module grammars::Function

start syntax Function
	= Var "(" VarList ")" "{"
	;

syntax VarList
	=  {Var ","}+ 
	|
	;
	
syntax Var = StdType Id; 

lexical Float 
	= Int("."Int)?("E"("+"|"-")?Int)?;

lexical Int 
	= [0-9]+;

lexical String
	= "\"" [a-z]* "\""
	; 
	
lexical StdType = "int" | "float" | "str";

keyword ControlFlowWord = "if" | "else" | "while"|"for";

lexical Id = [a-z] !<< [a-z]+ !>> [a-z] \ (StdType|ControlFlowWord);
