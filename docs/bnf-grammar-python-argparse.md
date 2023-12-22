# Backus–Naur Form Grammar: python argparse

## Common parts

Common parts definition of optional
```
<optional> ::= <flag> 
             | <flag> " " <argument>
<positional> ::= <name_identifier> 
               | <choices_identifier>

<flag> ::= <double_switch> <name_identifier> 
         | <switch> <name_identifier>
<argument> ::= <argument_question> 
			 | <argument_plus>
			 | <argument_star>
			 | <argument_count>

<argument_question> ::= "[" <identifiers> "]"
<argument_plus> ::= "[" <identifiers> " " <argument_star> "]"
<argument_star> ::= "[" <identifiers> " " <rest> "]"
<argument_count> ::= <identifiers> 
				   | <identifiers> <argument_count>

<identifiers> ::= <name_identifier> 
                | <choices_identifier>

<choices_identifier> ::= "{" <choice_identifiers> "}"
<choice_identifiers> ::= <name_identifier>
					   | <name_identifier> "," <choice_identifiers>

<name_identifier> ::= <digit> 
			   | <digit> <identifier_characters>
			   | <letter>
			   | <letter> <identifier_characters>
			   | <symbol>
			   | <symbol> <identifier_characters>

<identifier_characters> ::= <identifier_character> 
						  | <identifier_character> <identifier_characters>

<identifier_character> ::= <symbol> 
						 | <switch>
						 | <digit> 
						 | <letter>

<double_switch> ::= <switch> <switch>
<switch> ::= "-"
<rest> ::= "..."
<ambiguous> ::= <double_switch>
<symbol> ::= "_" | ":" | "?" | "." | ","
<digit> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
<letter> ::= "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J"
           | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T"
           | "U" | "V" | "W" | "X" | "Y" | "Z" | "a" | "b" | "c" | "d"
           | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n"
           | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x"
           | "y" | "z"
```
