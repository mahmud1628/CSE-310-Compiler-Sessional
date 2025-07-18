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
	extern int label_count;
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

	void writeLabel()
	{
		writeIntoCodeFile("L" + std::to_string(label_count) + ":\n");
		label_count++;
	}

	void writeJumpConditionByRelop(const std::string optr)
	{
		if(optr == "<=")
		{
			writeIntoCodeFile("\tjnle L" + std::to_string(label_count) + "\n");
		}
		else if(optr == "!=")
		{
			writeIntoCodeFile("\tje L" + std::to_string(label_count) + "\n");
		}
		else if(optr == "==")
		{
			writeIntoCodeFile("\tjne L" + std::to_string(label_count) + "\n");
		}
		else if(optr == "<")
		{
			writeIntoCodeFile("\tjge L" + std::to_string(label_count) + "\n");
		}
		else if(optr == ">") 
		{
			writeIntoCodeFile("\tjle L" + std::to_string(label_count) + "\n");
		}
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
					writeIntoCodeFile("\t; line " + std::to_string($SEMICOLON->getLine())+ "\n");
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
	      | IF LPAREN expression RPAREN
		  {
			int falseLabel = label_count++;
			writeIntoCodeFile("\tcmp ax, 1\n");
			writeIntoCodeFile("\tjne L" + std::to_string(falseLabel) + "\n");
		  }
		  statement
		  {
			writeIntoCodeFile("L" + std::to_string(falseLabel) + ":\n"); // use the same falseLabel here
		  }
		  | IF LPAREN expression RPAREN
		  {
			int falseLabel = label_count++;
			int endLabel = label_count++;
			writeIntoCodeFile("\tcmp ax, 1\n");
			writeIntoCodeFile("\tjne L" + std::to_string(falseLabel) + "\n");
		  }
		  statement
		  {
			writeIntoCodeFile("\tjmp L" + std::to_string(endLabel) + "\n");
			writeIntoCodeFile("L" + std::to_string(falseLabel) + ":\n");
		  }
		  ELSE statement
		  {
			writeIntoCodeFile("L" + std::to_string(endLabel) + ":\n");
		  }
	      | WHILE LPAREN expression RPAREN statement
	      | PRINTLN LPAREN ID RPAREN SEMICOLON
		  {
			writeIntoCodeFile("\t; line " + std::to_string($ID->getLine()) + "\n");
			SymbolInfo * info = symbolTable.lookup($ID->getText());
			if(info->getType() == "global")
			{
				writeIntoCodeFile("\tmov ax, " + $ID->getText() + "\n");
			}
			else if(info->getType() == "local")
			{
				std::string varName = "[bp - " + std::to_string(info->getStackOffset()) + "]";
				writeIntoCodeFile("\tmov ax, " + varName + "\n");
			}
			writeIntoCodeFile("\tcall print_output\n\tcall new_line\n");
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
		         | rel_expression LOGICOP 
				 {
					int shortLabel = label_count++;
					int endLabel = label_count++;
					std::string optr = $LOGICOP->getText();

					if(optr == "||")
					{
						writeIntoCodeFile("\tcmp ax, 0\n");
						writeIntoCodeFile("\tjne L" + std::to_string(shortLabel) + "\n");
					}
					else if(optr == "&&")
					{
						writeIntoCodeFile("\tcmp ax, 0\n");
						writeIntoCodeFile("\tje L" + std::to_string(shortLabel) + "\n");
					}
				 } 
				 rel_expression 
				 {
					if(optr == "||") 
					{
						writeIntoCodeFile("\tcmp ax, 0\n");
						writeIntoCodeFile("\tjne L" + std::to_string(shortLabel) + "\n");
						writeIntoCodeFile("\tmov ax, 0\n");
						writeIntoCodeFile("\tjmp L" + std::to_string(endLabel) + "\n");
						writeIntoCodeFile("L" + std::to_string(shortLabel) + ":\n");
						writeIntoCodeFile("\tmov ax, 1\n");
						writeIntoCodeFile("L" + std::to_string(endLabel) + ":\n");
					} 
					else if(optr == "&&") 
					{
						writeIntoCodeFile("\tcmp ax, 0\n");
						writeIntoCodeFile("\tje L" + std::to_string(shortLabel) + "\n");
						writeIntoCodeFile("\tmov ax, 1\n");
						writeIntoCodeFile("\tjmp L" + std::to_string(endLabel) + "\n");
						writeIntoCodeFile("L" + std::to_string(shortLabel) + ":\n");
						writeIntoCodeFile("\tmov ax, 0\n");
						writeIntoCodeFile("L" + std::to_string(endLabel) + ":\n");
					}
				 }	
		         ;
			
rel_expression	: simple_expression 
		        | simple_expression RELOP {writeIntoCodeFile("\tpush ax\n");} simple_expression	
				{
					writeIntoCodeFile("\tpop bx\n");
					writeIntoCodeFile("\tcmp bx, ax\n");
					writeJumpConditionByRelop($RELOP->getText());
					writeIntoCodeFile("\tmov ax, 1\n");
					writeIntoCodeFile("\tjmp L" + std::to_string(label_count + 1) + "\n");
					writeLabel();
					writeIntoCodeFile("\tmov ax, 0\n");
					writeLabel();
				}
		        ;
				
simple_expression 
				  : term 
		          | simple_expression ADDOP {writeIntoCodeFile("\tpush ax\n");} term 
				  {
					writeIntoCodeFile("\tpop bx\n");
					if($ADDOP->getText() == "+")
					{
						writeIntoCodeFile("\tadd bx, ax\n");
					}
					else 
					{
						writeIntoCodeFile("\tsub bx, ax\n");
					}
					writeIntoCodeFile("\tmov ax, bx\n");
				  }
		          ;
					
term 
	 :	unary_expression
     |  term MULOP {writeIntoCodeFile("\tpush ax\n");} unary_expression
	 {
		writeIntoCodeFile("\tpop bx\n");
		writeIntoCodeFile("\txchg ax,bx\n");
		if($MULOP->getText() == "*")
		{
			writeIntoCodeFile("\tmul bx\n");
		}
		else if($MULOP->getText() == "/")
		{
			writeIntoCodeFile("\tmov dx,0h\n");
			writeIntoCodeFile("\tdiv bx\n");
		}
		else 
		{
			writeIntoCodeFile("\tmov dx,0h\n");
			writeIntoCodeFile("\tdiv bx\n");	
			writeIntoCodeFile("\tmov ax, dx\n");		
		}
	 }
     ;

unary_expression 
				: ADDOP unary_expression  
				{
					if($ADDOP->getText() == "-")
					{
						writeIntoCodeFile("\tneg ax\n");
					}
				}
		         | NOT unary_expression 
		         | factor 
		         ;
	
factor	
		: v=variable 
		{
			writeIntoCodeFile("\tmov ax, " + $v.varName + " ; line " + std::to_string($v.start->getLine()) + "\n");
		}
	    | ID LPAREN argument_list RPAREN
	    | LPAREN expression RPAREN
        | CONST_INT 
		{
			writeIntoCodeFile("\tmov ax, " + $CONST_INT->getText() + " ; line " + std::to_string($CONST_INT->getLine()) + "\n");
		}
        | CONST_FLOAT
        | v=variable INCOP 
		{
			writeIntoCodeFile("\tmov ax, " + $v.varName + " ; line " + std::to_string($v.start->getLine()) + "\n");
			writeIntoCodeFile("\tinc ax\n");
			writeIntoCodeFile("\tmov " + $v.varName + ", ax\n");
		}
        | variable DECOP
        ;
	
argument_list : arguments
			  |
			  ;
	
arguments : arguments COMMA logic_expression
	      | logic_expression
	      ;