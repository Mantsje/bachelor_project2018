module grammars::toRegularGrammarTesters::RewrittenRascallike

import Grammar;

start syntax Exp =
  left  ( Exp "+" Exp 
  		| Exp "-" Exp) 
  | Exp_1 
  ;

syntax Exp_3 =
  Number 
  | bracket "("  Exp  ")" 
  ;

syntax Exp_2 =
  Exp_3 
  | right Exp_2  "^"  Exp_2 
  ;

syntax Exp_1 =
  Exp_2 
  | left ( Exp_1  "*"  Exp_1 
  		 | Exp_1  "/"  Exp_1) 
  ;

lexical Number =
  [0-9]+ (  "."  [0-9]+  )? (  "E"  ("+" | "-")?  [0-9]+  )? 
  ;

layout Whitespace  =
  [\t-\n \a0C-\a0D \ ]* 
  ;
