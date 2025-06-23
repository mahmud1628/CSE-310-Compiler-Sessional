parser grammar C8086Parser;

options {
    tokenVocab = C8086Lexer;
}

@parser::header {
    #include <iostream>
    #include <fstream>
    #include <string>
    #include <cstdlib>
    #include "C8086Lexer.h"
	#include "2105120_SymbolTable.hpp"
	#include <vector>
	#include <map>

    extern std::ofstream parserLogFile;
    extern std::ofstream errorFile;

    extern int syntaxErrorCount;

	extern SymbolTable symbolTable;
	
	extern std::string current_const_type, assign_type, var_type, term_operand_type, unary_e_operand_type;

	extern vector<string> declaration_list_ids;
	extern map<string, string> variableTypes;
}

@parser::members {
    void writeIntoparserLogFile(const std::string message) {
        if (!parserLogFile) {
            std::cout << "Error opening parserLogFile.txt" << std::endl;
            return;
        }

        parserLogFile << message << std::endl;
        parserLogFile.flush();
    }

    void writeIntoErrorFile(const std::string message) {
        if (!errorFile) {
            std::cout << "Error opening errorFile.txt" << std::endl;
            return;
        }
        errorFile << message << std::endl;
        errorFile.flush();
    }
}


start : p=program
	{
		writeIntoparserLogFile("Line " + std::to_string($p.stop->getLine()) + ": start : program\n");
		writeIntoparserLogFile(symbolTable.getSymbolTableAsString());
		writeIntoparserLogFile("Total number of lines: " + std::to_string($p.stop->getLine()));
		writeIntoparserLogFile("Total number of errors: " + std::to_string(syntaxErrorCount));
	}
	;

program returns [std::string program_text]
	: p=program un=unit 
	{
		$program_text = $p.program_text + "\n" + $un.unit_text;
		writeIntoparserLogFile("Line " + std::to_string($un.stop->getLine()) + ": program : program unit\n");
		writeIntoparserLogFile($p.program_text + "\n" + $un.unit_text + "\n");
	} 
	| un=unit 
	{
		$program_text = $un.unit_text;
		writeIntoparserLogFile("Line " + std::to_string($un.stop->getLine()) + ": program : unit\n");
		writeIntoparserLogFile($un.unit_text + "\n");
	}
	;
	
unit returns [std::string unit_text]
	: vd=var_declaration 
	{
		$unit_text = $vd.vd_text;
		writeIntoparserLogFile(
			"Line " + std::to_string($vd.start->getLine()) + ": unit : var_declaration\n"
		);
		writeIntoparserLogFile(
			$vd.vd_text + "\n"
		);
	}
    | fd=func_declaration
	{
		$unit_text = $fd.fd_text;
		writeIntoparserLogFile("Line " + std::to_string($fd.start->getLine()) + ": unit : func_declaration\n");
		writeIntoparserLogFile($fd.fd_text + "\n");
	}
    | fdef=func_definition
	{
		$unit_text = $fdef.fdef_text;
		writeIntoparserLogFile("Line " + std::to_string($fdef.stop->getLine()) + ": unit : func_definition\n");
		writeIntoparserLogFile($fdef.fdef_text + "\n");		
	}
    ;
     
func_declaration returns [std::string fd_text]
		: ts=type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			
		}
		| ts=type_specifier ID LPAREN RPAREN SEMICOLON 
		{
			$fd_text = $ts.ctx->getText() + " " + $ID->getText() + "();";
			writeIntoparserLogFile("Line " + std::to_string($ts.start->getLine()) + ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n");
			writeIntoparserLogFile($ts.ctx->getText() + " " + $ID->getText() + "();\n");

			symbolTable.insert($ID->getText(), "func");
		}
		;
		 
func_definition returns [std::string fdef_text]
	: ts=type_specifier ID {symbolTable.insert($ID->getText(), "func");} LPAREN {symbolTable.enterScope();} pl=parameter_list RPAREN cs=compound_statement
	{
		$fdef_text = $ts.text + " " + $ID->getText() + $LPAREN->getText() + $pl.pl_text + $RPAREN->getText() + $cs.cs_text;
		writeIntoparserLogFile("Line " + std::to_string($cs.stop->getLine()) + ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n");
		writeIntoparserLogFile($fdef_text + "\n");
	}
	| ts=type_specifier ID {symbolTable.insert($ID->getText(), "func");} LPAREN {symbolTable.enterScope();} RPAREN cs=compound_statement
	{
		$fdef_text = $ts.text + " " + $ID->getText() + $LPAREN->getText() + $RPAREN->getText() + $cs.cs_text;
		writeIntoparserLogFile("Line " + std::to_string($cs.stop->getLine()) + ": func_definition : type_specifier ID LPAREN RPAREN compound_statement\n");
		writeIntoparserLogFile($fdef_text + "\n");
	}
	;				


parameter_list returns [std::string pl_text]
		: pl=parameter_list COMMA ts=type_specifier ID
		{
			$pl_text = $pl.pl_text + "," + $ts.text + " " + $ID->getText();
			writeIntoparserLogFile("Line " + std::to_string($ts.start->getLine()) + ": parameter_list : parameter_list COMMA type_specifier ID\n");
			writeIntoparserLogFile($pl_text + "\n");

			symbolTable.insert($ID->getText(), $ts.text);
		}
		| parameter_list COMMA type_specifier
 		| ts=type_specifier ID
		{
			$pl_text = $ts.text + " " + $ID->getText();
			writeIntoparserLogFile("Line " + std::to_string($ts.start->getLine()) + ": parameter_list : type_specifier ID\n");
			writeIntoparserLogFile($ts.text + " " + $ID->getText() + "\n");
			
			symbolTable.insert($ID->getText(), $ts.text);
		}
		| type_specifier
 		;

 		
compound_statement returns [std::string cs_text]
		: LCURL ss=statements RCURL
		{
			$cs_text = $LCURL->getText() + "\n" + $ss.statements_text + "\n" + $RCURL->getText();
			writeIntoparserLogFile("Line " + std::to_string($RCURL->getLine()) + ": compound_statement : LCURL statements RCURL\n");
			writeIntoparserLogFile($cs_text + "\n");

			writeIntoparserLogFile(symbolTable.getSymbolTableAsString());
			symbolTable.exitScope();
		}
		| LCURL RCURL
		;
 		    
var_declaration returns [std::string vd_text]
    : t=type_specifier dl=declaration_list sm=SEMICOLON {
		$vd_text = $t.text + " " + $dl.dl_text + $sm->getText();
		writeIntoparserLogFile(
			"Line " + std::to_string($sm->getLine()) + ": var_declaration : type_specifier declaration_list SEMICOLON\n"
		);
		writeIntoparserLogFile(
			$t.text + " " + $dl.dl_text + $sm->getText() + "\n"
		);

		for(int i=0; i<declaration_list_ids.size();i++)
			symbolTable.insert(declaration_list_ids[i], $t.text);
	}
    | t=type_specifier de=declaration_list_err sm=SEMICOLON
    ;

declaration_list_err returns [std::string error_name]: {
        $error_name = "Error in declaration list";
    };

 		 
type_specifier returns [std::string name_line]	
        : INT {
            $name_line = "type: INT at line" + std::to_string($INT->getLine());
			writeIntoparserLogFile(
				std::string("Line " + std::to_string($INT->getLine()) + ": type_specifier : INT\n")
			);
			writeIntoparserLogFile(
				$INT->getText() + "\n"
			);
        }
 		| FLOAT {
            $name_line = "type: FLOAT at line" + std::to_string($FLOAT->getLine());
			writeIntoparserLogFile(
				std::string("Line " + std::to_string($FLOAT->getLine()) + ": type_specifier : FLOAT\n")
			);
			writeIntoparserLogFile(
				$FLOAT->getText() + "\n"
			);
        }
 		| VOID {
            $name_line = "type: VOID at line" + std::to_string($VOID->getLine());
			writeIntoparserLogFile(
				std::string("Line " + std::to_string($VOID->getLine()) + ": type_specifier : VOID\n")
			);
			writeIntoparserLogFile(
				$VOID->getText() + "\n"
			);
        }
 		;
 		
declaration_list returns [std::string dl_text]
		: dl=declaration_list COMMA ID 
		{
			$dl_text = $dl.dl_text + $COMMA->getText() + $ID->getText();
			writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : declaration_list COMMA ID\n");
			writeIntoparserLogFile($dl_text + "\n");

			//symbolTable.insert($ID->getText(), "ID");
			declaration_list_ids.push_back($ID->getText());
			variableTypes[$ID->getText()] = "variable";
		}
 		| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		| ID 
		{
			// bool inserted = symbolTable.insert($ID->getText(), "ID");
			SymbolInfo *info = symbolTable.lookup($ID->getText());
			if(info != nullptr) 
			{
				syntaxErrorCount++;
				std::string errorMessage = "Error at line " + std::to_string($ID->getLine()) + ": Multiple declaration of " + $ID->getText();
				writeIntoparserLogFile(errorMessage + "\n");
				writeIntoErrorFile(errorMessage + "\n");
			}
			else 
			{
				declaration_list_ids.push_back($ID->getText());
				variableTypes[$ID->getText()] = "variable";
			}
			$dl_text = $ID->getText();
			writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : ID\n");
			writeIntoparserLogFile($dl_text + "\n");
			
		}
 		| ID LTHIRD CONST_INT RTHIRD
		{
			$dl_text = $ID->getText() + $LTHIRD->getText() + $CONST_INT->getText() + $RTHIRD->getText();
			writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : ID LTHIRD CONST_INT RTHIRD\n");
			writeIntoparserLogFile($dl_text + "\n");

			// symbolTable.insert($ID->getText(), "ID");
			declaration_list_ids.push_back($ID->getText());
			variableTypes[$ID->getText()] = "array";
		}
 		;
 		  
statements returns [std::string statements_text]
	: s=statement
	{
		$statements_text = $s.statement_text;
		writeIntoparserLogFile("Line " + std::to_string($s.start->getLine()) + ": statements : statement\n");
		writeIntoparserLogFile($statements_text + "\n");
	}
	| ss=statements s=statement
	{
		$statements_text = $ss.statements_text + "\n" + $s.statement_text;
		writeIntoparserLogFile("Line " + std::to_string($s.start->getLine()) + ": statements : statements statement\n");
		writeIntoparserLogFile($statements_text + "\n");
	}
	;
	   
statement returns [std::string statement_text]
	: vd=var_declaration
	{
		$statement_text = $vd.vd_text;
		writeIntoparserLogFile("Line " + std::to_string($vd.start->getLine()) + ": statement : var_declaration\n");
		writeIntoparserLogFile($statement_text + "\n");				
	}
	| es=expression_statement 
	{
		$statement_text = $es.expression_statement_text;
		writeIntoparserLogFile("Line " + std::to_string($es.start->getLine()) + ": statement : expression_statement\n");
		writeIntoparserLogFile($statement_text + "\n");				
	}
	| compound_statement
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement
	| IF LPAREN expression RPAREN statement
	| IF LPAREN expression RPAREN statement ELSE statement
	| WHILE LPAREN expression RPAREN statement
	| PRINTLN LPAREN ID RPAREN SEMICOLON
	| RETURN e=expression SEMICOLON
	{
		$statement_text = "return " + $e.expression_text + ";";
		writeIntoparserLogFile("Line " + std::to_string($RETURN->getLine()) + ": statement : RETURN expression SEMICOLON\n");
		writeIntoparserLogFile($statement_text + "\n");
	}
	;
	  
expression_statement returns [std::string expression_statement_text]
			: SEMICOLON			
			| e=expression SEMICOLON
			{
				$expression_statement_text = $e.expression_text + ";";
				writeIntoparserLogFile("Line " + std::to_string($e.start->getLine()) + ": expression_statement : expression SEMICOLON\n");
				writeIntoparserLogFile($expression_statement_text + "\n");				
			} 
			;
	  
variable returns [std::string variable_text]
	: ID 
	{
		$variable_text = $ID->getText();
		writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": variable : ID\n");

		SymbolInfo *info = symbolTable.lookup($ID->getText());
		if(info == nullptr) 
		{
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + std::to_string($ID->getLine()) + ": Undeclared variable " + $ID->getText();
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
		}
		else 
		{
			var_type = info->getType();
			// std::cout << $ID->getText() << " " << var_type << std::endl;
		}
		writeIntoparserLogFile($variable_text + "\n");
	}		
	| ID LTHIRD e=expression RTHIRD 
	{
		$variable_text = $ID->getText() + $LTHIRD->getText() + $e.expression_text + $RTHIRD->getText();
		writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": variable : ID LTHIRD expression RTHIRD\n");
		if(current_const_type != "INT") 
		{
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + std::to_string($ID->getLine()) + ": Expression inside third brackets not an integer";
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
		}
		writeIntoparserLogFile($variable_text + "\n");
	}
	;
	 
 expression returns [std::string expression_text]
 	: le=logic_expression
	{
		$expression_text = $le.logic_expression_text;
		writeIntoparserLogFile("Line " + std::to_string($le.start->getLine()) + ": expression : logic_expression\n");
		writeIntoparserLogFile($expression_text + "\n");
	}	
	|  v=variable ASSIGNOP le=logic_expression 
	{
		$expression_text = $v.variable_text + $ASSIGNOP->getText() + $le.logic_expression_text;
		writeIntoparserLogFile("Line " + std::to_string($v.start->getLine()) + ": expression : variable ASSIGNOP logic_expression\n");

		if(variableTypes.find($v.variable_text) != variableTypes.end() && variableTypes[$v.variable_text] == "array") {
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + std::to_string($v.start->getLine()) + ": Type mismatch, " + $v.variable_text + " is an array";
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
		}

		if(var_type == "int" && assign_type == "float")
		{
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + std::to_string($v.start->getLine()) + ": Type Mismatch";
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
		}
		var_type = "";

		writeIntoparserLogFile($expression_text + "\n");
	}
	;
			
logic_expression returns [std::string logic_expression_text]
		: re=rel_expression 
		{
			$logic_expression_text = $re.rel_expression_text;
			writeIntoparserLogFile("Line " + std::to_string($re.start->getLine()) + ": logic_expression : rel_expression\n");
			writeIntoparserLogFile($logic_expression_text + "\n");
		}
		| re1=rel_expression LOGICOP re2=rel_expression 
		{
			$logic_expression_text = $re1.rel_expression_text + $LOGICOP->getText() + $re2.rel_expression_text;
			writeIntoparserLogFile("Line " + std::to_string($re1.start->getLine()) + ": logic_expression : rel_expression LOGICOP rel_expression\n");
			writeIntoparserLogFile($logic_expression_text + "\n");
		}	
		;
			
rel_expression	returns [std::string rel_expression_text]
		: se=simple_expression 
		{
			$rel_expression_text = $se.simple_expression_text;
			writeIntoparserLogFile("Line " + std::to_string($se.start->getLine()) + ": rel_expression : simple_expression\n");
			writeIntoparserLogFile($rel_expression_text + "\n");
		}
		| se1=simple_expression RELOP se2=simple_expression
		{
			$rel_expression_text = $se1.simple_expression_text + $RELOP->getText() + $se2.simple_expression_text;
			writeIntoparserLogFile("Line " + std::to_string($se1.start->getLine()) + ": rel_expression : simple_expression RELOP simple_expression\n");
			writeIntoparserLogFile($rel_expression_text + "\n");
		}
		;
				
simple_expression returns [std::string simple_expression_text]
		: t=term 
		{
			$simple_expression_text = $t.term_text;
			writeIntoparserLogFile("Line " + std::to_string($t.start->getLine()) + ": simple_expression : term\n");
			writeIntoparserLogFile($simple_expression_text + "\n");
		}
		| se=simple_expression ADDOP t=term 
		{
			$simple_expression_text = $se.simple_expression_text + $ADDOP->getText() + $t.term_text;
			writeIntoparserLogFile("Line " + std::to_string($se.start->getLine()) + ": simple_expression : simple_expression ADDOP term\n");
			writeIntoparserLogFile($simple_expression_text + "\n");
		}
		;
					
term returns [std::string term_text]
	:	ue=unary_expression
	{
		$term_text = $ue.unary_expression_text;
		writeIntoparserLogFile("Line " + std::to_string($ue.start->getLine()) + ": term : unary_expression\n");
		writeIntoparserLogFile($term_text + "\n");

		term_operand_type = unary_e_operand_type;
	}
    |  t=term MULOP ue=unary_expression
	{
		$term_text = $t.term_text + $MULOP->getText() + $ue.unary_expression_text;
		writeIntoparserLogFile("Line " + std::to_string($t.start->getLine()) + ": term : term MULOP unary_expression\n");

		if($MULOP->getText() == "%")
		{
			if(term_operand_type != "int" || unary_e_operand_type != "int")
			{
				syntaxErrorCount++;
				std::string errorMessage = "Error at line " + std::to_string($t.start->getLine()) + ": Non-Integer operand on modulus operator";
				writeIntoparserLogFile(errorMessage + "\n");
				writeIntoErrorFile(errorMessage + "\n");
			}
		}

		assign_type = "";

		writeIntoparserLogFile($term_text + "\n");
	}
    ;

unary_expression returns [std::string unary_expression_text]
		: ADDOP unary_expression  
		| NOT unary_expression 
		| f=factor 
		{
			$unary_expression_text = $f.factor_text;
			writeIntoparserLogFile("Line " + std::to_string($f.start->getLine()) + ": unary_expression : factor\n");
			writeIntoparserLogFile($unary_expression_text + "\n");

			unary_e_operand_type = assign_type;
		}
		;
	
factor	returns [std::string factor_text]
	: v=variable 
	{
		$factor_text = $v.variable_text;
		writeIntoparserLogFile("Line " + std::to_string($v.start->getLine()) + ": factor : variable\n");
		writeIntoparserLogFile($factor_text + "\n");
	}
	| ID LPAREN al=argument_list RPAREN
	{
		$factor_text = $ID->getText() + $LPAREN->getText() + $al.arglist_text + $RPAREN->getText();
		writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": factor : ID LPAREN argument_list RPAREN\n");
		writeIntoparserLogFile($factor_text + "\n");		
	}
	| LPAREN e=expression RPAREN
	{
		$factor_text = $LPAREN->getText() + $e.expression_text + $RPAREN->getText();
		writeIntoparserLogFile("Line " + std::to_string($LPAREN->getLine()) + ": factor : LPAREN expression RPAREN\n");
		writeIntoparserLogFile($factor_text + "\n");		
	}
	| CONST_INT 
	{
		$factor_text = $CONST_INT->getText();
		writeIntoparserLogFile("Line " + std::to_string($CONST_INT->getLine()) + ": factor : CONST_INT\n");
		writeIntoparserLogFile($factor_text + "\n");	

		current_const_type = "INT";	
		assign_type = "int";
	}
	| CONST_FLOAT
	{
		$factor_text = $CONST_FLOAT->getText();
		writeIntoparserLogFile("Line " + std::to_string($CONST_FLOAT->getLine()) + ": factor : CONST_FLOAT\n");
		writeIntoparserLogFile($factor_text + "\n");	

		current_const_type = "FLOAT";	
		assign_type = "float";		
	}
	| variable INCOP 
	| variable DECOP
	;
	
argument_list returns [std::string arglist_text]
		: a=arguments
		{
			$arglist_text = $a.args_text;
			writeIntoparserLogFile("Line " + std::to_string($a.start->getLine()) + ": argument_list : arguments\n");
			writeIntoparserLogFile($arglist_text + "\n");		
		}
		|
		;
	
arguments returns [std::string args_text]
	: a=arguments COMMA le=logic_expression
	{
		$args_text = $a.args_text + $COMMA->getText() + $le.logic_expression_text;
		writeIntoparserLogFile("Line " + std::to_string($a.start->getLine()) + ": arguments : arguments COMMA logic_expression\n");
		writeIntoparserLogFile($args_text + "\n");
	}
	| le=logic_expression
	{
		$args_text = $le.logic_expression_text;
		writeIntoparserLogFile("Line " + std::to_string($le.start->getLine()) + ": arguments : logic_expression\n");

		if(variableTypes.find($le.logic_expression_text) != variableTypes.end() && variableTypes[$le.logic_expression_text] == "array") {
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + std::to_string($le.start->getLine()) + ": Type mismatch, " + $le.logic_expression_text + " is an array";
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
		}
		writeIntoparserLogFile($args_text + "\n");				
	}
	;
