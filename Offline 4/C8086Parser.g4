parser grammar C8086Parser;

options {
    tokenVocab = C8086Lexer;
}

@parser::header {
	#include <iostream>
	#include <fstream>
	#include <stack>
	#include "C8086Lexer.h"
	#include "2105120_SymbolTable.hpp"

	extern std::ofstream asmCodeFile;
	extern SymbolTable symbolTable;
	extern bool codeSegmentStarted;
	extern int label_count;
	extern stack<std::string> currentFunctions;
}

@parser::members {
	void writeIntoCodeFile(const std::string code) {
		asmCodeFile << code;
		asmCodeFile.flush();
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
		currentFunctions.push(procName);
	}
	void writeProcEnd(const std::string procName, int paramSize) {
		if(procName == "main")
		{
			writeIntoCodeFile("\tmov ah, 4ch\n\tint 21h\n");
		}
		else
		{
			if(paramSize == 0)
				writeIntoCodeFile("\tret\n");
			else
				writeIntoCodeFile("\tret " + std::to_string(paramSize) + "\n");
		}
		writeIntoCodeFile(procName + " endp\n\n");
		currentFunctions.pop();
	}

	void writeLabel(std::string label)
	{
		writeIntoCodeFile("L" + label + ":\n");
	}

	void writeJumpConditionByRelop(const std::string optr, int falseLabel)
	{
		std::string jmpStr;
		if(optr == "<=") jmpStr = "jnle";
		else if(optr == "!=") jmpStr = "je";
		else if(optr == "==") jmpStr = "jne";
		else if(optr == "<") jmpStr = "jge";
		else if(optr == ">") jmpStr = "jle";

		writeIntoCodeFile("\t" + jmpStr + " L" + std::to_string(falseLabel) + "\n");
	}

	void declareVariable(std::string varName, int count)
	{
		if(symbolTable.getCurrentScopeId() == "1") // global scope
		{
			writeIntoCodeFile("\t" + varName + " dw 0h\n");
			symbolTable.insert(varName, "global");
		}
		else // local scope
		{
			writeIntoCodeFile("\tsub sp, 2\n");
			symbolTable.insert(varName, "local", count * 2);
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
				: type_specifier 
				{
					writeCodeSegment();
				} 
				ID 
				{
					writeProcName($ID->getText());
				} 
				LPAREN 
				{
					symbolTable.enterScope(); writeIntoCodeFile("\tpush bp\n\tmov bp, sp\n");
				} 
				pl=parameter_list 
				{
					int paramSize = $pl.paramNames.size();
					for(int i = 0; i < paramSize;i++)
					{
						symbolTable.insert($pl.paramNames[i], "param", 4 + (paramSize - i - 1) * 2);
					}
				}
				RPAREN compound_statement 
				{
					writeIntoCodeFile("L" + currentFunctions.top() + "end:\n");
					writeIntoCodeFile("\tmov sp, bp\n\tpop bp\n");
					writeProcEnd($ID->getText(), paramSize * 2);
					symbolTable.exitScope();
				}
		        | type_specifier {writeCodeSegment();} ID {writeProcName($ID->getText());} LPAREN {symbolTable.enterScope(); writeIntoCodeFile("\tpush bp\n\tmov bp, sp\n");} RPAREN compound_statement
				{
					writeIntoCodeFile("L" + currentFunctions.top() + "end:\n");
					writeIntoCodeFile("\tmov sp, bp\n\tpop bp\n");
					writeProcEnd($ID->getText(), 0);
					symbolTable.exitScope();
				}
 		        ;				


parameter_list returns [std::vector<std::string> paramNames]
				: pl=parameter_list COMMA type_specifier ID
				{
					$paramNames = $pl.paramNames;
					$paramNames.push_back($ID->getText());
				}
		        | parameter_list COMMA type_specifier
 		        | type_specifier ID
				{
					$paramNames.push_back($ID->getText());
				}
		        | type_specifier
 		        ;

 		
compound_statement : LCURL {symbolTable.enterScope();} statements RCURL {symbolTable.exitScope();}
 		           | LCURL {symbolTable.enterScope();} RCURL {symbolTable.exitScope();}
 		           ;
 		    
var_declaration 
				: type_specifier dl=declaration_list SEMICOLON
				{

				}
                ;

 		 
type_specifier : INT
 		       | FLOAT
 		       | VOID
 		       ;
 		
declaration_list returns [int count]
				 : dl=declaration_list COMMA ID
				 {
					$count = $dl.count + 1;
					declareVariable($ID->getText(), $count);
				 }
 		         | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		         | ID
				 {
					$count = 1;
					declareVariable($ID->getText(), $count);
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
	      | FOR LPAREN expression_statement 
		  {
			int conditionLabel = label_count++;
			int endLabel = label_count++;
			int statementLabel = label_count++;
			int incrementLabel = label_count++;
			writeLabel(std::to_string(conditionLabel));
		  } 
		  expression_statement
		  {
			writeIntoCodeFile("\tcmp ax, 0\n");
			writeIntoCodeFile("\tje L" + std::to_string(endLabel) + "\n");
			writeIntoCodeFile("\tjne L" + std::to_string(statementLabel) + "\n");
			writeLabel(std::to_string(incrementLabel));
		  } 
		  expression
		  {
			writeIntoCodeFile("\tjmp L" + std::to_string(conditionLabel) + "\n");
			writeLabel(std::to_string(statementLabel));
		  } 
		  RPAREN statement
		  {
			writeIntoCodeFile("\tjmp L" + std::to_string(incrementLabel) + "\n");
			writeLabel(std::to_string(endLabel));
		  }
	      | IF LPAREN expression RPAREN
		  {
			int falseLabel = label_count++;
			writeIntoCodeFile("\tcmp ax, 1\n");
			writeIntoCodeFile("\tjne L" + std::to_string(falseLabel) + "\n");
		  }
		  statement
		  {
			writeLabel(std::to_string(falseLabel)); // use the same falseLabel here
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
			writeLabel(std::to_string(falseLabel));
		  }
		  ELSE statement
		  {
			writeLabel(std::to_string(endLabel));
		  }
	      | WHILE LPAREN
		  {
			int conditionLabel = label_count++;
			int endLabel = label_count++;
			writeLabel(std::to_string(conditionLabel));
		  } 
		  expression
		  {
			writeIntoCodeFile("\tcmp ax, 0\n");
			writeIntoCodeFile("\tje L" + std::to_string(endLabel) + "\n");
		  } 
		  RPAREN statement
		  {
			writeIntoCodeFile("\tjmp L" + std::to_string(conditionLabel) + "\n");
			writeLabel(std::to_string(endLabel));
		  }
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
		  {
			writeIntoCodeFile("\tjmp L" + currentFunctions.top() + "end\n");
		  }
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
			else if(info->getType() == "local")
			{
				$varName = "[bp - " + std::to_string(info->getStackOffset()) + "]";
			}
			else if(info->getType() == "param")
			{
				$varName = "[bp + " + std::to_string(info->getStackOffset()) + "]";
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
			
logic_expression
				 : rel_expression 
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
						writeLabel(std::to_string(shortLabel));
						writeIntoCodeFile("\tmov ax, 1\n");
						writeLabel(std::to_string(endLabel));
					} 
					else if(optr == "&&") 
					{
						writeIntoCodeFile("\tcmp ax, 0\n");
						writeIntoCodeFile("\tje L" + std::to_string(shortLabel) + "\n");
						writeIntoCodeFile("\tmov ax, 1\n");
						writeIntoCodeFile("\tjmp L" + std::to_string(endLabel) + "\n");
						writeLabel(std::to_string(shortLabel));
						writeIntoCodeFile("\tmov ax, 0\n");
						writeLabel(std::to_string(endLabel));
					}
				 }	
		         ;
			
rel_expression
				: simple_expression 
		        | simple_expression RELOP {writeIntoCodeFile("\tpush ax\n");} simple_expression	
				{
					writeIntoCodeFile("\tpop bx\n");
					writeIntoCodeFile("\tcmp bx, ax\n");
					int falseLabel = label_count++;
					int endLabel = label_count++;
					writeJumpConditionByRelop($RELOP->getText(), falseLabel);
					writeIntoCodeFile("\tmov ax, 1\n");
					writeIntoCodeFile("\tjmp L" + std::to_string(endLabel) + "\n");
					writeLabel(std::to_string(falseLabel));
					writeIntoCodeFile("\tmov ax, 0\n");
					writeLabel(std::to_string(endLabel));
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
		{
			std::string funcName = $ID->getText();
			writeIntoCodeFile("\tcall " + funcName + "\n");
		}
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
			writeIntoCodeFile("\tdec ax\n");
		}
        | v=variable DECOP
		{
			writeIntoCodeFile("\tmov ax, " + $v.varName + " ; line " + std::to_string($v.start->getLine()) + "\n");
			writeIntoCodeFile("\tdec ax\n");
			writeIntoCodeFile("\tmov " + $v.varName + ", ax\n");	
			writeIntoCodeFile("\tinc ax\n");		
		}
        ;
	
argument_list
			  : arguments
			  |
			  ;
	
arguments
		  : arguments COMMA logic_expression
		  {
			writeIntoCodeFile("\tpush ax\n");
		  }
	      | logic_expression
		  {
			writeIntoCodeFile("\tpush ax\n");
		  }
	      ;