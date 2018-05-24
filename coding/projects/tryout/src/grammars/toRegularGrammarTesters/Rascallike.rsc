module grammars::expressions::Rascallike

import ParseTree;
import String;

layout Whitespace = [\t\f\n\r\ ]*; 
    
lexical Number 
	= [0-9]+("."[0-9]+)?("E"("+"|"-")?[0-9]+)?;

start syntax Exp 
  = n: Number
  | bracket "(" Exp ")"     
  > right Exp lhs "^" Exp rhs
  > left (Exp lhs "*" Exp rhs | Exp lhs "/" Exp rhs )           
  > left (Exp lhs "+" Exp rhs | Exp lhs "-" Exp rhs )           
  ;

  
real eval(str txt) 								= eval(parse(#Exp, txt));
real eval((Exp)`<Number n>`) 					= toReal("<n>");
real eval((Exp)`(<Exp e>)`) 					= eval(e);
real eval((Exp)`<Exp e1>^<Exp e2>`) 			= (1.0 | it * eval(e1)| x <- [0 .. eval(e2)]);
real eval((Exp)`<Exp e1><Mul_Op op><Exp e2>`) 	= eval(op, eval(e1), eval(e2));
real eval((Exp)`<Exp e1><Plus_Op op><Exp e2>`) 	= eval(op, eval(e1), eval(e2));
real eval(Mul_Op op, real lhs, real rhs) {
	if ("<op>" == "*") return lhs * rhs; else return lhs / rhs;
}
real eval(Plus_Op op, real lhs, real rhs) {
	if ("<op>" == "+") return lhs + rhs; else return lhs - rhs;
}