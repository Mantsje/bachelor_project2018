module grammars::A_Plain

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
  = @Context="keyword.control.flow" "b" 
  | @Context="null keyword.control.flow" D "b" 
  ;

lexical D
  = @Context="storage.type null" "d" B 
  | @Context="storage.type" "d" 
  ;


  