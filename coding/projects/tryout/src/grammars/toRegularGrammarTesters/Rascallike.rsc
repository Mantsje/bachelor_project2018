module grammars::toRegularGrammarTesters::Rascallike

import ParseTree;
import String;


layout Whitespace = [\t\f\n\r\ ]* !>> [\t\f\n\r\ ]; 
    
lexical Number 
	= [0-9]+("."[0-9]+)?("E"("+"|"-")?[0-9]+)?;

start syntax Exp 
  = n: Number
  | bracket "(" Exp ")"     
  > right Exp lhs "^" Exp rhs
  > left (Exp lhs "*" Exp rhs | Exp lhs "/" Exp rhs )           
  > left (Exp lhs "+" Exp rhs | Exp lhs "-" Exp rhs )           
  ;


real pow(real a, real b) = (1.0 | it * a | _ <- [0..b]);

real eval((Exp)`<Number n>`) = toReal("<n>");
real eval((Exp)`(<Exp e>)`) = eval(e);
real eval((Exp)`<Exp e1>+<Exp e2>`) = eval(e1) + eval(e2);
real eval((Exp)`<Exp e1>-<Exp e2>`) = eval(e1) - eval(e2);
real eval((Exp)`<Exp e1>*<Exp e2>`) = eval(e1) * eval(e2);
real eval((Exp)`<Exp e1>/<Exp e2>`) = eval(e1) / eval(e2);
real eval((Exp)`<Exp e1>^<Exp e2>`) = pow(eval(e1), eval(e2));
real eval(str input) = eval(parse(#Exp, input));