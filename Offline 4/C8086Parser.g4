parser grammar C8086Parser;

options {
    tokenVocab = C8086Lexer;
}

@parser::header {
	#include <iostream>
	#include <fstream>
	#include "C8086Lexer.h"
	#include "2105120_SymbolTable.hpp"

	extern std::ofstream asmCodeFile;
	extern SymbolTable symbolTable;
	extern bool codeSegmentStarted;
}

@parser::members {
	void writeIntoCodeFile(const std::string code) {
		asmCodeFile << code;
	}
	void writeCodeSegment() {
		if(codeSegmentStarted == false) {
			writeIntoCodeFile(".code\n");
			codeSegmentStarted = true;
		}
	}
	void writeProcName(const std::string procName) {
		writeIntoCodeFile(procName + " proc\n");
		if(procName == "main") {
			writeIntoCodeFile("\tmov ax, @data\n\tmov ds, ax\n\n");
		}
	}
	void writeProcEnd(const std::string procName) {
		if(procName == "main")
		{
			writeIntoCodeFile("\tmov ah, 4ch\n\tint 21h\n");
		}
		writeIntoCodeFile(procName + " endp\n\n");
	}
}


start : program
        ;

program : program unit 
	    | unit
	    ;
	
unit : var_declaration
     | func_declaration
     | func_definition
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		        | type_specifier ID LPAREN RPAREN SEMICOLON
		        ;
		 
func_definition 
				: type_specifier {writeCodeSegment();} ID {writeProcName($ID->getText());} LPAREN {symbolTable.enterScope(); writeIntoCodeFile("\tmov bp, sp\n");} parameter_list RPAREN compound_statement 
				{
					writeIntoCodeFile("\tmov sp, bp\n");
					writeProcEnd($ID->getText());
				}
		        | type_specifier {writeCodeSegment();} ID {writeProcName($ID->getText());} LPAREN {symbolTable.enterScope(); writeIntoCodeFile("\tmov bp, sp\n");} RPAREN compound_statement
				{
					writeIntoCodeFile("\tmov sp, bp\n");
					writeProcEnd($ID->getText());
				}
 		        ;				


parameter_list  : parameter_list COMMA type_specifier ID
		        | parameter_list COMMA type_specifier
 		        | type_specifier ID
		        | type_specifier
 		        ;

 		
compound_statement : LCURL statements RCURL
 		           | LCURL RCURL
 		           ;
 		    
var_declaration 
				: type_specifier dl=declaration_list SEMICOLON
				{
					if(symbolTable.getCurrentScopeId() == "1") // global scope
					{
						for(auto s : $dl.variableNames)
						{
							writeIntoCodeFile("\t" + s + " dw 0h\n");
							symbolTable.insert(s, "global");
						}
					}
					else // local scope
					{
						for(int i = 1; i <= $dl.variableNames.size();i++)
						{
							symbolTable.insert($dl.variableNames[i - 1], "local", i * 2);
						}
						writeIntoCodeFile("\tsub sp, " + std::to_string($dl.variableNames.size() * 2) + "\n");
					}
				}
                ;

 		 
type_specifier : INT
 		       | FLOAT
 		       | VOID
 		       ;
 		
declaration_list returns [std::vector<std::string> variableNames]
				 : dl=declaration_list COMMA ID
				 {
					$variableNames = $dl.variableNames;
					$variableNames.push_back($ID->getText());
				 }
 		         | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		         | ID
				 {
					$variableNames.push_back($ID->getText());
				 }
 		         | ID LTHIRD CONST_INT RTHIRD
 		         ;
 		  
statements : statement
	       | statements statement
	       ;
	   
statement 
		  : var_declaration
	      | expression_statement
	      | compound_statement
	      | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	      | IF LPAREN expression RPAREN statement
	      | IF LPAREN expression RPAREN statement ELSE statement
	      | WHILE LPAREN expression RPAREN statement
	      | PRINTLN LPAREN ID RPAREN SEMICOLON
		  {
			SymbolInfo * info = symbolTable.lookup($ID->getText());
			if(info->getType() == "global")
			{
				writeIntoCodeFile("\tmov ax, " + $ID->getText() + "\n");
			}
			writeIntoCodeFile("\tcall print_output\n");
		  }
	      | RETURN expression SEMICOLON
	      ;
	  
expression_statement 	: SEMICOLON			
			            | expression SEMICOLON 
			            ;
	  
variable returns [std::string varName]
		 : ID
		 {
			SymbolInfo * info = symbolTable.lookup($ID->getText());
			if(info->getType() == "global")
			{
				$varName = $ID->getText();
			}
			else
			{
				$varName = "[bp - " + std::to_string(info->getStackOffset()) + "]";
			}
		 } 		
	     | ID LTHIRD expression RTHIRD 
	     ;
	 
 expression 
 			: logic_expression	
	        | v=variable ASSIGNOP logic_expression 
			{
				writeIntoCodeFile("\tmov " + $v.varName + ", ax\n");
			}	
	        ;
			
logic_expression : rel_expression 	
		         | rel_expression LOGICOP rel_expression 	
		         ;
			
rel_expression	: simple_expression 
		        | simple_expression RELOP simple_expression	
		        ;
				
simple_expression : term 
		          | simple_expression ADDOP term 
		          ;
					
term :	unary_expression
     |  term MULOP unary_expression
     ;

unary_expression : ADDOP unary_expression  
		         | NOT unary_expression 
		         | factor 
		         ;
	
factor	
		: variable 
	    | ID LPAREN argument_list RPAREN
	    | LPAREN expression RPAREN
        | CONST_INT 
		{
			writeIntoCodeFile("\tmov ax, " + $CONST_INT->getText() + "\n");
		}
        | CONST_FLOAT
        | variable INCOP 
        | variable DECOP
        ;
	
argument_list : arguments
			  |
			  ;
	
arguments : arguments COMMA logic_expression
	      | logic_expression
	      ;