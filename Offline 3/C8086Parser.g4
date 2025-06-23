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
	extern bool is_func_declaration, is_func_definition;
	extern vector<pair<string, string>> parameter_list_ids;
	extern SymbolInfo *currentFunction;
	extern vector<string> argument_list_types;
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

	void function_def(const std::string name, const std::string ret_type)
	{
		SymbolInfo *info = symbolTable.lookup(name);
		if(info == nullptr)
		{
			symbolTable.insert(name, "func");
			SymbolInfo *f = symbolTable.lookup(name);
			f->setFuncReturnType(ret_type);
		}
	}

	void type_error_check(const std::string name, const std::string ret_type, const std::string line)
	{
		SymbolInfo *info = symbolTable.lookup(name);
		std::string type = info->getType();
		if(type != "func")
		{
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + line + ": Multiple declaration of " + name;
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");	
			return;			
		}
		int paramCount = info->getFuncParamsSize();
		if(paramCount != parameter_list_ids.size() && info->getDeclarationStatus() == true)
		{
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + line + ": Total number of arguments mismatch with declaration in function " + name;
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");	
			return;			
		}
		info->setFuncParams(parameter_list_ids);
		std::string ret = info->getFuncReturnType();
		if(ret != ret_type)
		{
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + line + ": Return type mismatch of " + name;
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
		}
	}

	void check_argument(const std::string name, const std::string line)
	{
		SymbolInfo *info = symbolTable.lookup(name);
		if(info == nullptr) return;
		vector<pair<string, string>> params = info->getFuncParams();
		// std::cout << params.size() << " " << argument_list_types.size() << " " << name << "\n";
		if(params.size() != argument_list_types.size())
		{	
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + line + ": Total number of arguments mismatch with declaration in function " + name;
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
			return;
		}
		else 
		{
			for(int i = 0; i < params.size(); i++)
			{
				if(params[i].second != argument_list_types[i])
				{
					syntaxErrorCount++;
					std::string errorMessage = "Error at line " + line + ": " + std::to_string(i + 1) + "th argument mismatch in function " + name;
					writeIntoparserLogFile(errorMessage + "\n");
					writeIntoErrorFile(errorMessage + "\n");
					return;
				}
			}
		}
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
		: ts=type_specifier {is_func_declaration = true;} ID LPAREN pl=parameter_list RPAREN SEMICOLON
		{
			$fd_text = $ts.ctx->getText() + " " + $ID->getText() + "(" + $pl.pl_text + ");";
			writeIntoparserLogFile("Line " + std::to_string($ts.start->getLine()) + ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n");
			writeIntoparserLogFile($fd_text + "\n");

			symbolTable.insert($ID->getText(), "func");
			SymbolInfo *info = symbolTable.lookup($ID->getText());
			info->setFuncReturnType($ts.text);
			info->setFuncParams(parameter_list_ids);
			parameter_list_ids.clear();
			info->setDeclarationStatus(true);
			is_func_declaration = false;			
		}
		| ts=type_specifier {is_func_declaration = true;} ID LPAREN RPAREN SEMICOLON 
		{
			$fd_text = $ts.ctx->getText() + " " + $ID->getText() + "();";
			writeIntoparserLogFile("Line " + std::to_string($ts.start->getLine()) + ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n");
			writeIntoparserLogFile($ts.ctx->getText() + " " + $ID->getText() + "();\n");

			symbolTable.insert($ID->getText(), "func");
			SymbolInfo *info = symbolTable.lookup($ID->getText());
			info->setFuncReturnType($ts.text);
			info->setDeclarationStatus(true);
			is_func_declaration = false;
		}
		;
		 
func_definition returns [std::string fdef_text]
	: ts=type_specifier ID {function_def($ID->getText(), $ts.text); is_func_definition = true;} LPAREN pl=parameter_list {type_error_check($ID->getText(), $ts.text, std::to_string($ID->getLine()));} RPAREN {currentFunction = symbolTable.lookup($ID->getText());} cs=compound_statement
	{
		$fdef_text = $ts.text + " " + $ID->getText() + $LPAREN->getText() + $pl.pl_text + $RPAREN->getText() + $cs.cs_text;
		writeIntoparserLogFile("Line " + std::to_string($cs.stop->getLine()) + ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n");
		writeIntoparserLogFile($fdef_text + "\n");
		currentFunction = nullptr;
		is_func_definition = false;
	}
	| ts=type_specifier ID {function_def($ID->getText(), $ts.text);} LPAREN RPAREN cs=compound_statement
	{
		$fdef_text = $ts.text + " " + $ID->getText() + $LPAREN->getText() + $RPAREN->getText() + $cs.cs_text;
		writeIntoparserLogFile("Line " + std::to_string($cs.stop->getLine()) + ": func_definition : type_specifier ID LPAREN RPAREN compound_statement\n");
		writeIntoparserLogFile($fdef_text + "\n");
	}
	| ts=type_specifier ID {function_def($ID->getText(), $ts.text);} LPAREN pl=parameter_list ADDOP RPAREN {
				syntaxErrorCount++;
		std::string errorMessage = "Error at line " + std::to_string($ADDOP->getLine()) + ": syntax error, unexpected ADDOP, expecting RPAREN or COMMA";
		writeIntoparserLogFile(errorMessage + "\n");
		writeIntoErrorFile(errorMessage + "\n");
	} cs=compound_statement
	{
		$fdef_text = $ts.text + " " + $ID->getText() + $LPAREN->getText() + $pl.pl_text + $RPAREN->getText() + $cs.cs_text;
	}
	;				


parameter_list returns [std::string pl_text]
		: pl=parameter_list COMMA ts=type_specifier ID
		{

			if(!is_func_declaration || is_func_declaration)
			{
				// symbolTable.insert($ID->getText(), $ts.text);
				bool found = false;
				for(int i = 0; i < parameter_list_ids.size(); i++)
					if(parameter_list_ids[i].first == $ID->getText())
						found = true;
				if(found == false)
					parameter_list_ids.push_back({$ID->getText(), $ts.text});
				else 
				{
					syntaxErrorCount++;
					std::string errorMessage = "Error at line " + std::to_string($ts.start->getLine()) + ": Multiple declaration of " + $ID->getText() + " in parameter";
					writeIntoparserLogFile(errorMessage + "\n");
					writeIntoErrorFile(errorMessage + "\n");
				}
			}

			$pl_text = $pl.pl_text + "," + $ts.text + " " + $ID->getText();
			writeIntoparserLogFile("Line " + std::to_string($ts.start->getLine()) + ": parameter_list : parameter_list COMMA type_specifier ID\n");
			writeIntoparserLogFile($pl_text + "\n");
		}
		| parameter_list COMMA type_specifier
 		| ts=type_specifier ID
		{
			$pl_text = $ts.text + " " + $ID->getText();
			writeIntoparserLogFile("Line " + std::to_string($ts.start->getLine()) + ": parameter_list : type_specifier ID\n");
			writeIntoparserLogFile($ts.text + " " + $ID->getText() + "\n");
			
			if(!is_func_declaration || is_func_declaration)
			{
				// symbolTable.insert($ID->getText(), $ts.text);
				parameter_list_ids.push_back({$ID->getText(), $ts.text});
			}
		}
		| ts=type_specifier
		{
			$pl_text = $ts.text;
			writeIntoparserLogFile("Line " + std::to_string($ts.start->getLine()) + ": parameter_list : type_specifier\n");
			writeIntoparserLogFile($ts.text + "\n");			
		}
 		;

 		
compound_statement returns [std::string cs_text]
		: LCURL {symbolTable.enterScope();
			if(parameter_list_ids.size() > 0) 
			{
				for(int i = 0; i < parameter_list_ids.size(); i++)
					symbolTable.insert(parameter_list_ids[i].first, parameter_list_ids[i].second);
				
				parameter_list_ids.clear();
			}
		} ss=statements RCURL
		{
			$cs_text = $LCURL->getText() + "\n" + $ss.statements_text + "\n" + $RCURL->getText();
			writeIntoparserLogFile("Line " + std::to_string($RCURL->getLine()) + ": compound_statement : LCURL statements RCURL\n");
			writeIntoparserLogFile($cs_text + "\n");

			writeIntoparserLogFile(symbolTable.getSymbolTableAsString());
			symbolTable.exitScope();
		}
		| LCURL {symbolTable.enterScope();
			if(parameter_list_ids.size() > 0) 
			{
				for(int i = 0; i < parameter_list_ids.size(); i++)
					symbolTable.insert(parameter_list_ids[i].first, parameter_list_ids[i].second);
				
				parameter_list_ids.clear();
			}
		}  RCURL
		{
			$cs_text = $LCURL->getText() + $RCURL->getText();
			writeIntoparserLogFile("Line " + std::to_string($RCURL->getLine()) + ": compound_statement : LCURL RCURL\n");
			writeIntoparserLogFile($cs_text + "\n");

			writeIntoparserLogFile(symbolTable.getSymbolTableAsString());
			symbolTable.exitScope();
		}
		;
 		    
var_declaration returns [std::string vd_text]
    : t=type_specifier dl=declaration_list sm=SEMICOLON {
		$vd_text = $t.text + " " + $dl.dl_text + $sm->getText();
		writeIntoparserLogFile(
			"Line " + std::to_string($sm->getLine()) + ": var_declaration : type_specifier declaration_list SEMICOLON\n"
		);
		if($t.text == "void")
		{
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + std::to_string($sm->getLine()) + ": Variable type cannot be " + $t.text;
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
		}

		for(int i=0; i<declaration_list_ids.size();i++)
			symbolTable.insert(declaration_list_ids[i], $t.text);
		declaration_list_ids.clear();

		writeIntoparserLogFile(
			$t.text + " " + $dl.dl_text + $sm->getText() + "\n"
		);
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
 		| dl=declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		{
			$dl_text = $dl.dl_text + "," + $ID->getText() + $LTHIRD->getText() + $CONST_INT->getText() + $RTHIRD->getText();

			// symbolTable.insert($ID->getText(), "ID");
			SymbolInfo *info = symbolTable.lookupAtCurrentScope($ID->getText());
			if(info == nullptr)
			{
				declaration_list_ids.push_back($ID->getText());
				variableTypes[$ID->getText()] = "array";
			}
			else 
			{
				syntaxErrorCount++;
				std::string errorMessage = "Error at line " + std::to_string($ID->getLine()) + ": Multiple declaration of " + $ID->getText();
				writeIntoparserLogFile(errorMessage + "\n");
				writeIntoErrorFile(errorMessage + "\n");
			}
			writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n");
			writeIntoparserLogFile($dl_text + "\n");			
		}
 		| ID 
		{
			// bool inserted = symbolTable.insert($ID->getText(), "ID");
			SymbolInfo *info = symbolTable.lookupAtCurrentScope($ID->getText());
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
		| dl=declaration_list ADDOP ID
		{
			$dl_text = $dl.dl_text;
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + std::to_string($ID->getLine()) + ": syntax error, unexpected ADDOP, expecting COMMA or SEMICOLON";
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");

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
		writeIntoparserLogFile("Line " + std::to_string($s.stop->getLine()) + ": statements : statements statement\n");
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
		if(currentFunction != nullptr) currentFunction = nullptr;
		$statement_text = $es.expression_statement_text;
		writeIntoparserLogFile("Line " + std::to_string($es.start->getLine()) + ": statement : expression_statement\n");
		writeIntoparserLogFile($statement_text + "\n");				
	}
	| cs=compound_statement
	{
		$statement_text = $cs.cs_text;
		writeIntoparserLogFile("Line " + std::to_string($cs.stop->getLine()) + ": statement : compound_statement\n");
		writeIntoparserLogFile($statement_text + "\n");
	}
	| FOR LPAREN es1=expression_statement es2=expression_statement e=expression RPAREN s=statement
	{
		$statement_text = $FOR->getText() + $LPAREN->getText() + $es1.expression_statement_text + $es2.expression_statement_text + $e.expression_text + $RPAREN->getText() + $s.statement_text;
		writeIntoparserLogFile("Line " + std::to_string($s.stop->getLine()) + ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n");
		writeIntoparserLogFile($statement_text + "\n");
	}
	| IF LPAREN e=expression RPAREN s=statement
	{
		$statement_text = $IF->getText() + $LPAREN->getText() + $e.expression_text + $RPAREN->getText() + $s.statement_text;
		writeIntoparserLogFile("Line " + std::to_string($s.stop->getLine()) + ": statement : IF LPAREN expression RPAREN statement\n");
		writeIntoparserLogFile($statement_text + "\n");		
	}
	| IF LPAREN e=expression RPAREN s1=statement ELSE s2=statement
	{
		$statement_text = $IF->getText() + $LPAREN->getText() + $e.expression_text + $RPAREN->getText() + $s1.statement_text + $ELSE->getText() + " " + $s2.statement_text;
		writeIntoparserLogFile("Line " + std::to_string($s2.stop->getLine()) + ": statement : IF LPAREN expression RPAREN statement ELSE statement\n");
		writeIntoparserLogFile($statement_text + "\n");	
	}
	| WHILE LPAREN e=expression RPAREN s=statement
	{
		$statement_text = $WHILE->getText() + $LPAREN->getText() + $e.expression_text + $RPAREN->getText() + $s.statement_text;
		writeIntoparserLogFile("Line " + std::to_string($s.stop->getLine()) + ": statement : WHILE LPAREN expression RPAREN statement\n");
		writeIntoparserLogFile($statement_text + "\n");
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON
	{
		writeIntoparserLogFile("Line " + std::to_string($SEMICOLON->getLine()) + ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n");
		SymbolInfo *info = symbolTable.lookup($ID->getText());
		if(info == nullptr)
		{
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + std::to_string($ID->getLine()) + ": Undeclared variable " + $ID->getText();
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
		}
		$statement_text = $PRINTLN->getText() + $LPAREN->getText() + $ID->getText() + $RPAREN->getText() + ";";
		writeIntoparserLogFile($statement_text + "\n");		
	}
	| RETURN e=expression SEMICOLON
	{
		$statement_text = "return " + $e.expression_text + ";";
		writeIntoparserLogFile("Line " + std::to_string($RETURN->getLine()) + ": statement : RETURN expression SEMICOLON\n");
		writeIntoparserLogFile($statement_text + "\n");

		if(currentFunction != nullptr && currentFunction->getFuncReturnType() == "void")
		{
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + std::to_string($RETURN->getLine()) + ": Cannot return value from function " + currentFunction->getName() + " with void return type";
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
		}
	}
	;
	  
expression_statement returns [std::string expression_statement_text]
			: SEMICOLON	
			{
				$expression_statement_text = ";";
				writeIntoparserLogFile("Line " + std::to_string($SEMICOLON->getLine()) + ": expression_statement : SEMICOLON\n");
				writeIntoparserLogFile($expression_statement_text + "\n");
			}		
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
			// std::cout << $ID->getText() << " " << variableTypes[$ID->getText()] << "\n";
			if(variableTypes[$ID->getText()] == "array") argument_list_types.push_back("array");
			else argument_list_types.push_back(info->getType());
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
		if(variableTypes.find($ID->getText()) != variableTypes.end() && variableTypes[$ID->getText()] != "array")
		{
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + std::to_string($ID->getLine()) + ": " + $ID->getText() + " not an array";
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
		}
		SymbolInfo *info = symbolTable.lookup($ID->getText());
		if(info) var_type = info->getType();
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

		if(currentFunction != nullptr && is_func_definition == false)
		{
			if(currentFunction->getType() == "func" && currentFunction->getFuncReturnType() == "void")
			{
				syntaxErrorCount++;
				std::string errorMessage = "Error at line " + std::to_string($v.start->getLine()) + ": Void function used in expression";
				writeIntoparserLogFile(errorMessage + "\n");
				writeIntoErrorFile(errorMessage + "\n");
			}
			currentFunction = nullptr;
		}

		writeIntoparserLogFile($expression_text + "\n");
	}
	| UNRECOGNIZED
	{
		syntaxErrorCount++;
		std::string errorMessage = "Error at line " + std::to_string($UNRECOGNIZED->getLine()) + ": Unrecognized character " + $UNRECOGNIZED->getText();
		writeIntoparserLogFile(errorMessage + "\n");
		writeIntoErrorFile(errorMessage + "\n");
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
		| se=simple_expression ADDOP ASSIGNOP t=term
		{
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + std::to_string($se.start->getLine()) + ": syntax error, unexpected ASSIGNOP";
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
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

			if($ue.unary_expression_text == "0")
			{
				syntaxErrorCount++;
				std::string errorMessage = "Error at line " + std::to_string($t.start->getLine()) + ": Modulus by Zero";
				writeIntoparserLogFile(errorMessage + "\n");
				writeIntoErrorFile(errorMessage + "\n");				
			}
		}

		assign_type = "";

		if(currentFunction != nullptr)
		{
			if(currentFunction->getType() == "func" && currentFunction->getFuncReturnType() == "void")
			{
				syntaxErrorCount++;
				std::string errorMessage = "Error at line " + std::to_string($t.start->getLine()) + ": Void function used in expression";
				writeIntoparserLogFile(errorMessage + "\n");
				writeIntoErrorFile(errorMessage + "\n");
			}
			currentFunction = nullptr;
		}
		if(argument_list_types.size() > 0) argument_list_types.pop_back();
		writeIntoparserLogFile($term_text + "\n");
	}
    ;

unary_expression returns [std::string unary_expression_text]
		: ADDOP ue=unary_expression  
		{
			$unary_expression_text = $ADDOP->getText() + $ue.unary_expression_text;
			writeIntoparserLogFile("Line " + std::to_string($ue.stop->getLine()) + ": unary_expression : ADDOP unary_expression\n");
			writeIntoparserLogFile($unary_expression_text + "\n");			
		}
		| NOT ue=unary_expression 
		{
			$unary_expression_text = $NOT->getText() + $ue.unary_expression_text;
			writeIntoparserLogFile("Line " + std::to_string($ue.stop->getLine()) + ": unary_expression : NOT unary_expression\n");
			writeIntoparserLogFile($unary_expression_text + "\n");			
		}
		| f=factor 
		{
			$unary_expression_text = $f.factor_text;
			writeIntoparserLogFile("Line " + std::to_string($f.start->getLine()) + ": unary_expression : factor\n");
			writeIntoparserLogFile($unary_expression_text + "\n");

			unary_e_operand_type = assign_type;
		}
		;
	
factor returns [std::string factor_text]
	: v=variable 
	{
		$factor_text = $v.variable_text;
		writeIntoparserLogFile("Line " + std::to_string($v.start->getLine()) + ": factor : variable\n");
		writeIntoparserLogFile($factor_text + "\n");
	}
	| ID LPAREN {argument_list_types.clear();} al=argument_list RPAREN
	{
		writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": factor : ID LPAREN argument_list RPAREN\n");
		SymbolInfo *info = symbolTable.lookup($ID->getText());
		if(info == nullptr)
		{
			syntaxErrorCount++;
			std::string errorMessage = "Error at line " + std::to_string($ID->getLine()) + ": Undefined function " + $ID->getText();
			writeIntoparserLogFile(errorMessage + "\n");
			writeIntoErrorFile(errorMessage + "\n");
		}
		$factor_text = $ID->getText() + $LPAREN->getText() + $al.arglist_text + $RPAREN->getText();
		check_argument($ID->getText(), std::to_string($ID->getLine()));
		writeIntoparserLogFile($factor_text + "\n");
		argument_list_types.clear();	
		assign_type = "";
		currentFunction = info;	
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
		argument_list_types.push_back("int");
	}
	| CONST_FLOAT
	{
		$factor_text = $CONST_FLOAT->getText();
		writeIntoparserLogFile("Line " + std::to_string($CONST_FLOAT->getLine()) + ": factor : CONST_FLOAT\n");
		writeIntoparserLogFile($factor_text + "\n");	

		current_const_type = "FLOAT";	
		assign_type = "float";	
		argument_list_types.push_back("float");	
	}
	| v=variable INCOP 
	{
		$factor_text = $v.variable_text + $INCOP->getText();
		writeIntoparserLogFile("Line " + std::to_string($INCOP->getLine()) + ": factor : variable INCOP\n");
		writeIntoparserLogFile($factor_text + "\n");		
	}
	| v=variable DECOP
	{
		$factor_text = $v.variable_text + $DECOP->getText();
		writeIntoparserLogFile("Line " + std::to_string($DECOP->getLine()) + ": factor : variable DECOP\n");
		writeIntoparserLogFile($factor_text + "\n");		
	}
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
