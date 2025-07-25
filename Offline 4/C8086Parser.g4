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
	extern int localVarCount;
	extern bool isReturnPresent;
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
		else if(optr == ">=") jmpStr = "jnge";

		writeIntoCodeFile("\t" + jmpStr + " L" + std::to_string(falseLabel) + "\n");
	}

	void declareVariable(std::string varName)
	{
		if(symbolTable.getCurrentScopeId() == "1") // global scope
		{
			writeIntoCodeFile("\t" + varName + " dw 0h\n");
			symbolTable.insert(varName, "global");
		}
		else // local scope
		{
			localVarCount++;
			writeIntoCodeFile("\tsub sp, 2\n");
			symbolTable.insert(varName, "local", localVarCount * 2);
		}
	}

	void declareArray(std::string arrName, int size)
	{
		if(symbolTable.getCurrentScopeId() == "1") // global scope
		{
			writeIntoCodeFile("\t" + arrName + " dw " + std::to_string(size) + " dup (0)\n");
			symbolTable.insert(arrName, "global");
		}
		else // local scope
		{
			localVarCount += size;
			writeIntoCodeFile("\tsub sp, " + std::to_string(size * 2) + "\n");
			symbolTable.insert(arrName, "local", localVarCount * 2, size);
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
					writeIntoCodeFile("; definition of function " + $ID->getText() + " started, line no " + std::to_string($ID->getLine()) + "\n");
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
					if(isReturnPresent == true) writeIntoCodeFile("L" + currentFunctions.top() + "end:\n");
					isReturnPresent = false;
					writeIntoCodeFile("\tmov sp, bp\n\tpop bp\n");
					writeProcEnd($ID->getText(), paramSize * 2);
					localVarCount -= symbolTable.countLocalVarInCurrentScope();
					symbolTable.exitScope();
				}
		        | type_specifier 
				{
					writeCodeSegment();
				} 
				ID 
				{
					writeIntoCodeFile("; definition of function " + $ID->getText() + " started, line no " + std::to_string($ID->getLine()) + "\n");
					writeProcName($ID->getText());
				} 
				LPAREN {symbolTable.enterScope(); writeIntoCodeFile("\tpush bp\n\tmov bp, sp\n");} RPAREN compound_statement
				{
					if(isReturnPresent == true) writeIntoCodeFile("L" + currentFunctions.top() + "end:\n");
					isReturnPresent = false;
					writeIntoCodeFile("\tmov sp, bp\n\tpop bp\n");
					writeProcEnd($ID->getText(), 0);
					localVarCount -= symbolTable.countLocalVarInCurrentScope();
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

 		
compound_statement : LCURL {symbolTable.enterScope();} statements RCURL 
					{
						localVarCount -= symbolTable.countLocalVarInCurrentScope();
						symbolTable.exitScope();
					}
 		           | LCURL {symbolTable.enterScope();} RCURL 
				   {
						localVarCount -= symbolTable.countLocalVarInCurrentScope();
						symbolTable.exitScope();
					}
 		           ;
 		    
var_declaration 
				: ts=type_specifier 
				{
					writeIntoCodeFile("; variable declaration of line " + std::to_string($ts.start->getLine()) + "\n");
				} declaration_list SEMICOLON
                ;

 		 
type_specifier : INT
 		       | FLOAT
 		       | VOID
 		       ;
 		
declaration_list
				 : declaration_list COMMA ID
				 {
					declareVariable($ID->getText());
				 }
 		         | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
				 {
					int arrSize = stoi($CONST_INT->getText());
					declareArray($ID->getText(), arrSize);					
				 }
 		         | ID
				 {
					declareVariable($ID->getText());
				 }
 		         | ID LTHIRD CONST_INT RTHIRD
				 {
					int arrSize = stoi($CONST_INT->getText());
					declareArray($ID->getText(), arrSize);
				 }
 		         ;
 		  
statements : s=statement[-1]
	       | statements s=statement[-1]
	       ;
	   
statement [int endLabelInherited]
		  : var_declaration
	      | expression_statement
	      | compound_statement
	      | FOR
		  {
			writeIntoCodeFile("; for loop in line no " + std::to_string($FOR->getLine()) + "\n");
		  } LPAREN expression_statement 
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
			writeIntoCodeFile("\tje L" + std::to_string(endLabel) + " ; jump to end\n");
			writeIntoCodeFile("\tjne L" + std::to_string(statementLabel) + " ; jump to statement execution\n");
			writeLabel(std::to_string(incrementLabel));
		  } 
		  expression
		  {
			writeIntoCodeFile("\tjmp L" + std::to_string(conditionLabel) + " ; jump to condition checking\n");
			writeLabel(std::to_string(statementLabel));
		  } 
		  RPAREN s=statement[-1]
		  {
			writeIntoCodeFile("\tjmp L" + std::to_string(incrementLabel) + " ; jump to increment/decrement statement\n");
			writeLabel(std::to_string(endLabel));
		  }
	      | IF
		  {
			writeIntoCodeFile("; if statement in line no " + std::to_string($IF->getLine()) + "\n");
		  } LPAREN expression RPAREN
		  {
			int falseLabel;
			if($endLabelInherited >= 0) falseLabel = $endLabelInherited;
			else falseLabel = label_count++;
			writeIntoCodeFile("\tcmp ax, 0\n");
			writeIntoCodeFile("\tje L" + std::to_string(falseLabel) + " ; jump to false label\n");
		  }
		  s=statement[falseLabel]
		  {
			if($endLabelInherited < 0) writeLabel(std::to_string(falseLabel)); // use the same falseLabel here
		  }
		  | IF 
		  {
			writeIntoCodeFile("; if statement in line no " + std::to_string($IF->getLine()) + "\n");			
		  } LPAREN expression RPAREN
		  {
			int falseLabel = label_count++;
			int endLabel;
			if($endLabelInherited >= 0) endLabel = $endLabelInherited;
			else endLabel = label_count++;
			writeIntoCodeFile("\tcmp ax, 0\n");
			writeIntoCodeFile("\tje L" + std::to_string(falseLabel) + " ; jump to false label\n");
		  }
		  s=statement[-1]
		  {
			writeIntoCodeFile("\tjmp L" + std::to_string(endLabel) + " ; jump to end\n");
			writeLabel(std::to_string(falseLabel));
		  }
		  ELSE
		  {
			writeIntoCodeFile("; else statement in line no " + std::to_string($ELSE->getLine()) + "\n");
		  } s=statement[endLabel]
		  {
			if($endLabelInherited < 0) writeLabel(std::to_string(endLabel));
		  }
	      | WHILE 
		  {
			writeIntoCodeFile("; while loop in line no " + std::to_string($WHILE->getLine()) + "\n");
		  } LPAREN
		  {
			int conditionLabel = label_count++;
			int endLabel = label_count++;
			writeLabel(std::to_string(conditionLabel));
		  } 
		  expression
		  {
			writeIntoCodeFile("\tcmp ax, 0\n");
			writeIntoCodeFile("\tje L" + std::to_string(endLabel) + " ; jump to end\n");
		  } 
		  RPAREN s=statement[-1]
		  {
			writeIntoCodeFile("\tjmp L" + std::to_string(conditionLabel) + " ; jump to condition checking\n");
			writeLabel(std::to_string(endLabel));
		  }
	      | PRINTLN 
		  {
			writeIntoCodeFile("; print statement in line no " + std::to_string($PRINTLN->getLine()) + "\n");
		  } LPAREN ID RPAREN SEMICOLON
		  {
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
	      | RETURN 
		  {
			writeIntoCodeFile("; return statement in line no " + std::to_string($RETURN->getLine()) + "\n");
		  } expression SEMICOLON
		  {
			isReturnPresent = true;
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
		 {
			writeIntoCodeFile("\tmov bx, 2\n");
			writeIntoCodeFile("\tmul bx\n");
			SymbolInfo * info = symbolTable.lookup($ID->getText());
			if(info->getType() == "global")
			{
				writeIntoCodeFile("\tlea si, " + $ID->getText() + "\n");
				writeIntoCodeFile("\tadd si, ax\n");
				$varName = "[si]";
			}
			else if(info->getType() == "local")
			{
				writeIntoCodeFile("\tmov di, ax\n");
				$varName = "[bp - " + std::to_string(info->getStackOffset()) + " - di]";
			}
		 }
	     ;
	 
 expression 
 			: logic_expression	
	        | v=variable ASSIGNOP logic_expression 
			{
				writeIntoCodeFile("\tmov " + $v.varName + ", ax ; assignment operation of line " + std::to_string($ASSIGNOP->getLine()) + "\n");
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
						writeIntoCodeFile("\tjne L" + std::to_string(shortLabel) + " ; jump to true label\n");
					}
					else if(optr == "&&")
					{
						writeIntoCodeFile("\tcmp ax, 0\n");
						writeIntoCodeFile("\tje L" + std::to_string(shortLabel) + " ; jump to false label\n");
					}
				 } 
				 rel_expression 
				 {
					if(optr == "||") 
					{
						writeIntoCodeFile("\tcmp ax, 0\n");
						writeIntoCodeFile("\tjne L" + std::to_string(shortLabel) + " ; jump to true label\n");
						writeIntoCodeFile("\tmov ax, 0\n");
						writeIntoCodeFile("\tjmp L" + std::to_string(endLabel) + " ; jump to end\n");
						writeLabel(std::to_string(shortLabel));
						writeIntoCodeFile("\tmov ax, 1\n");
						writeLabel(std::to_string(endLabel));
					} 
					else if(optr == "&&") 
					{
						writeIntoCodeFile("\tcmp ax, 0\n");
						writeIntoCodeFile("\tje L" + std::to_string(shortLabel) + " ; jump to false label\n");
						writeIntoCodeFile("\tmov ax, 1\n");
						writeIntoCodeFile("\tjmp L" + std::to_string(endLabel) + " ; jump to end\n");
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
					writeIntoCodeFile("\tmov ax, 1 ; result of relational operation true\n");
					writeIntoCodeFile("\tjmp L" + std::to_string(endLabel) + "\n");
					writeLabel(std::to_string(falseLabel));
					writeIntoCodeFile("\tmov ax, 0 ; result of relational operation false\n");
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
						writeIntoCodeFile("\tadd bx, ax ; addition operation of line " + std::to_string($ADDOP->getLine()) + "\n");
					}
					else 
					{
						writeIntoCodeFile("\tsub bx, ax ; subtraction operation of line " + std::to_string($ADDOP->getLine()) + "\n");
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
			writeIntoCodeFile("\tmov ax, " + $v.varName + "; load variable of line " + std::to_string($v.start->getLine()) + "\n");
		}
	    | ID LPAREN argument_list RPAREN
		{
			std::string funcName = $ID->getText();
			writeIntoCodeFile("\tcall " + funcName + "\n");
		}
	    | LPAREN expression RPAREN
        | CONST_INT 
		{
			writeIntoCodeFile("\tmov ax, " + $CONST_INT->getText() + "; integer constant of line " + std::to_string($CONST_INT->getLine()) + " loaded to ax\n");
		}
        | CONST_FLOAT
        | v=variable INCOP 
		{
			writeIntoCodeFile("\tmov ax, " + $v.varName + "\n");
			writeIntoCodeFile("\tinc ax\n");
			writeIntoCodeFile("\tmov " + $v.varName + ", ax\n");
			writeIntoCodeFile("\tdec ax\n");
		}
        | v=variable DECOP
		{
			writeIntoCodeFile("\tmov ax, " + $v.varName + "\n");
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