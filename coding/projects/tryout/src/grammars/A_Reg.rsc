module grammars::A_Reg

start syntax S = A;

lexical A = B_D_ALT_PLUS;
  
lexical B_D_ALT_PLUS 
	= B_D_ALT B_D_ALT_PLUS 
	| B_D_ALT 
	;
  
syntax B_D_ALT
  = B 
  | D 
  ;

lexical B 
	= "b" B_end 
  	| D 
  	;

lexical B_end
  	= D_end 
  	| 
  	;

lexical D 
	= "d" D_end 
  	| "d" B 
  	;
	
lexical D_end 
	= "b" B_end 
	| 
  	;
  	
  	