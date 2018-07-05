module grammars::thesis::RascalExampleExp

// layout is lists of whitespace characters
layout MyLayout = [\t\n\ \r\f]*;

// identifiers are characters of lowercase alphabet letters, 
// not immediately preceded or followed by those (longest match)
// and not any of the reserved keywords
lexical Identifier = [a-z] !<< [a-z]+ !>> [a-z] \ MyKeywords;

// this defines the reserved keywords used in the definition of Identifier
keyword MyKeywords 
	= @Context="keyword.flow.conditional" "if" 
	| @Context="keyword.flow.conditional" "then" 
	| @Context="keyword.flow.conditional" "else" 
	| @Context="keyword.flow.conditional" "fi"
	;

// here is a recursive definition of expressions 
// using priority and associativity groups.
syntax Expression 
  = id: Identifier id
  | @Context="constant.language" null: "null"
  | bracket "(" Expression ")"
  > @Context="null keyword.operator.arithmetic null" left multi: Expression l "*" Expression r
  > left ( add: Expression l "+" Expression r
         | sub: Expression l "-" Expression r
         )
  ;