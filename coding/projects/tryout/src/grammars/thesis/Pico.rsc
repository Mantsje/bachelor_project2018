module grammars::thesis::Pico

import ParseTree;
import IO;

start syntax Program 
  = @Context="keyword.control.flow null null keyword.control.flow" program: "begin" Declarations decls {Statement  ";"}* body "end" ;

syntax Declarations 
  = @Context="keyword.declaration null" "declare" {IdType ","}* decls ";" ;  
 
syntax IdType = idtype: Id id ":" Type t;

syntax Statement 
  = assign: Id var ":="  Expression val 
  | @Context="keyword.control.flow null keyword.control.flow null keyword.control.flow null keyword.control.flow" 
  	cond: "if" Expression cond "then" {Statement ";"}*  thenPart "else" {Statement ";"}* elsePart "fi"
  | cond: "if" Expression cond "then" {Statement ";"}*  thenPart "fi"
  | @Context="keyword.control.flow null keyword.control.flow null keyword.control.flow" 
  	loop: "while" Expression cond "do" {Statement ";"}* body "od"
  ;  
     
syntax Type 
  = @Context="storage.type" natural:"natural" 
  | @Context="storage.type" string :"string" 
  | @Context="storage.type" nil    :"nil-type"
  ;

syntax Expression 
  = id: Id name
  | @Context="string.quoted.double" strcon: String string
  | @Context="constant.numeric.integer" natcon: Natural natcon
  | bracket "(" Expression e ")"
  > left concat: Expression lhs "||" Expression rhs
  > left ( add: Expression lhs "+" Expression rhs
         | min: Expression lhs "-" Expression rhs
         )
  ;

lexical Id  = ([a-z][a-z0-9]*) !>> [a-z0-9];
lexical Natural = [0-9]+ ;
lexical String = "\"" ![\"]*  "\"";

layout Layout = WhitespaceAndComment* !>> [\ \t\n\r%];

lexical WhitespaceAndComment 
   = [\ \t\n\r]
   | @Context="comment.block" "%" ![%]+ "%"
   | @Context="comment.line" "%%" ![\n]* $
   ;

public start[Program] program(str s) {
  return parse(#start[Program], s);
}

public start[Program] program(str s, loc l) {
  return parse(#start[Program], s, l);
} 
