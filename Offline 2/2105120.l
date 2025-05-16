%option noyywrap

%x char_const
%x string_const
%x comment_single_line
%x comment_multi_line

%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<string>
#include<iostream>
#include "2105120_SymbolTable.hpp"

using namespace std;

int line_count=1, error_count=0;
string str,str_for_log,cmnt,escaped,character;
int str_start, comment_start;

SymbolTable symbolTable = SymbolTable(7);

void increment_line_count(){
    line_count++;
}

string escaped_character_token(const char *text) {
    string s(text);
    if(s == "\\n") return "\n";
    if(s == "\\t") return "\t";
    if(s == "\\r") return "\r";
    if(s == "\\f") return "\f";
    if(s == "\\a") return "\a";
    if(s == "\\b") return "\b";
    if(s == "\\v") return "\v";
    if(s == "\\0") return "\0";
    if(s == "\\\"") return "\"";
    return s; // Return the original string if no match found
}

FILE *log_file;
FILE *token_file;

void write_log(const char *token, const char *lexeme){
    fprintf(log_file, "Line no %d: Token %s Lexeme %s found\n\n", line_count, token, lexeme);
}

void write_token(const char *token) {
    fprintf(token_file, "%s ", token);
}

void write_log_token(const char *token,const char *lexeme){
    write_log(token, lexeme);
    write_token(token);
}

void insert_to_symbol_table(const string & name, const string & type) {
    bool inserted = symbolTable.insert(name, type);
    if(inserted) symbolTable.printAllScopesToLog();
}

void insert_to_symbol_table(const char * name, const string & type) {
    string n(name);
    insert_to_symbol_table(n, type);
}

void final_print() {
    symbolTable.printAllScopesToLog();
    fprintf(log_file, "Total lines: %d\n", line_count);
    fprintf(log_file, "Total errors: %d", error_count);
}


%}

WHITESPACE [ \t\f\r\v]+ 
DIGIT [0-9]
CONST_INT {DIGIT}+
TOO_MANY_DECIMAL_POINTS {DIGIT}*\.{DIGIT}*\.[0-9.]*
ILL_FORMED_EXPONENT [Ee][-+\.0-9]+[-+Ee\.0-9]*
ILL_FORMED_NUMBER {DIGIT}+(\.[0-9]*)?{ILL_FORMED_EXPONENT}
CONST_FLOAT ({DIGIT}+\.{DIGIT}*([eE][+-]?{DIGIT}+)?|\.{DIGIT}+([eE][+-]?{DIGIT}+)?|{DIGIT}+[eE][+-]?{DIGIT}+)
SINGLE_CHAR [^\\'\n]\'
ESCAPED_CHAR \\[ntafrbv0\'\\]\'
MULTIPLE_CHAR [^'\n]+\'
NEWLINE \n
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*

%%

{WHITESPACE}    {
        
                }

{NEWLINE}   {
                increment_line_count();
            }

"if"    {
            write_log_token("<IF>", yytext);
        }

"else"  {
            write_log_token("<ELSE>", yytext);
        }

"goto"  {
            write_log_token("<GOTO>", yytext);
        }

"for"   {
            write_log_token("<FOR>", yytext);
        }

"while" {
            write_log_token("<WHILE>", yytext);
        }

"long"  {
            write_log_token("<LONG>", yytext);
        }

"do"    {
            write_log_token("<DO>", yytext);
        }

"break" {
            write_log_token("<BREAK>", yytext);
        }

"short" {
            write_log_token("<SHORT>", yytext);
        }

"int"   {
            write_log_token("<INT>", yytext);
        }

"char"  {
            write_log_token("<CHAR>", yytext);
        }

"static"    {
                write_log_token("<STATIC>", yytext);
            }

"float" {
            write_log_token("<FLOAT>", yytext);
        }

"double"    {
                write_log_token("<DOUBLE>", yytext);
            }

"unsigned"  {
                write_log_token("<UNSIGNED>", yytext);
            }

"void"  {
            write_log_token("<VOID>", yytext);
        }

"return"    {
                write_log_token("<RETURN>", yytext);
            }   

"switch"    {
                write_log_token("<SWITCH>", yytext);
            }

"case"  {
            write_log_token("<CASE>", yytext);
        }

"default"   {
                write_log_token("<DEFAULT>", yytext);
            }

"continue"  {
                write_log_token("<CONTINUE>", yytext);
            }

"+" |
"-" {   
        string token(yytext);
        token = "<ADDOP, " + token + ">";
        write_token(token.c_str());
        write_log("<ADDOP>", yytext);
    }

"*" |
"/" |
"%" {
        string token(yytext);
        token = "<MULOP, " + token + ">";
        write_token(token.c_str());
        write_log("<MULOP>", yytext);
    }

"++" |
"--" {
        string token(yytext);
        token = "<INCOP, " + token + ">";
        write_token(token.c_str());
        write_log("<INCOP>", yytext);
     }

"=" {   
        write_log("<ASSIGNOP>", yytext);
        write_token("<ASSIGNOP, =>");
    }

"&&" |
"||" {
        string token(yytext);
        token = "<LOGICOP, " + token + ">";
        write_token(token.c_str());
        write_log("<LOGICOP>", yytext);
     }

"!" {
        write_log("<NOT>", yytext);
        write_token("<NOT, !>");
    }

"<" |
">" |
"<=" |
">=" |
"==" |
"!=" {
        string token(yytext);
        token = "<RELOP, " + token + ">";
        write_token(token.c_str());
        write_log("<RELOP>", yytext);
     }

"(" {
        write_log("<LPAREN>", yytext);
        write_token("<LPAREN, (>");
    }

")" {
        write_log("<RPAREN>", yytext);
        write_token("<RPAREN, )>");
    }

"{" {   
        symbolTable.enterScope();
        write_log("<LCURL>", yytext);
        write_token("<LCURL, {>");
    }

"}" {   
        symbolTable.exitScope();
        write_log("<RCURL>", yytext);
        write_token("<RCURL, }>");
    }

"[" {
        write_log("<LTHIRD>", yytext);
        write_token("<LTHIRD, [>");
    }

"]" {
        write_log("<RTHIRD>", yytext);
        write_token("<RTHIRD, ]>");
    }

"," {
        write_log("<COMMA>", yytext);
        write_token("<COMMA, ,>");
    }

";" {
        write_log("<SEMICOLON>", yytext);
        write_token("<SEMICOLON, ;>");
    }

{IDENTIFIER}    {   
                    fprintf(token_file, "<ID, %s> ", yytext);
                    fprintf(log_file, "Line no %d: Token <ID> Lexeme %s found\n\n", line_count, yytext);
                    insert_to_symbol_table(yytext, "ID");
                }

{CONST_INT}     {   
                    fprintf(token_file, "<CONST_INT, %s> ", yytext);
                    fprintf(log_file, "Line no %d: Token <CONST_INT> Lexeme %s found\n\n", line_count, yytext);
                    insert_to_symbol_table(yytext, "CONST_INT");
                }

{TOO_MANY_DECIMAL_POINTS}   {
                                // Handle error for too many decimal points
                                error_count++;
                                fprintf(log_file, "Error at line no %d: Too many decimal points %s\n\n\n", line_count, yytext);
                            }


{CONST_FLOAT}   {
                    fprintf(token_file, "<CONST_FLOAT, %s> ", yytext);
                    fprintf(log_file, "Line no %d: Token <CONST_FLOAT> Lexeme %s found\n\n", line_count, yytext);
                    insert_to_symbol_table(yytext, "CONST_FLOAT");
                }

{ILL_FORMED_NUMBER}     {
                            // Handle error for ill-formed numbers
                            error_count++;
                            fprintf(log_file, "Error at line no %d: Ill formed number %s\n\n\n", line_count, yytext);
                        }

{TOO_MANY_DECIMAL_POINTS}{ILL_FORMED_EXPONENT}    {
                                                        // Handle error for too many decimal points
                                                        error_count++;
                                                        fprintf(log_file, "Error at line no %d: Too many decimal points %s\n\n\n", line_count, yytext);
                                                    }

{DIGIT}+{IDENTIFIER}+   {
                            // Handle error for identifier starting with digit
                            error_count++;
                            fprintf(log_file, "Error at line no %d: Invalid prefix on ID or invalid suffix on Number %s\n\n", line_count, yytext);
                        }

"\'"    {
            BEGIN char_const;
            yytext[0] = '\0';
            character = "";
        }


<char_const>{SINGLE_CHAR} {
                            // Single character, followed by closing '
                            int len = strlen(yytext);
                            yytext[len-1] = '\0'; // Remove the closing '
                            fprintf(token_file, "<CONST_CHAR, %s> ", yytext);
                            fprintf(log_file, "Line no %d: Token <CONST_CHAR> Lexeme \'%s\' found --> <CONST_CHAR, %s>\n\n", line_count, yytext, yytext);
                            string temp(yytext);
                            temp = "\'" + temp + "\'";
                            insert_to_symbol_table(temp, "CONST_CHAR");
                            BEGIN INITIAL;
                        }

<char_const>{ESCAPED_CHAR} {
                                // Escaped character, followed by closing '
                                int len = strlen(yytext);
                                yytext[len-1] = '\0'; // Remove the closing '
                                escaped = escaped_character_token(yytext);
                                fprintf(token_file, "<CONST_CHAR, %s> ", escaped.c_str());
                                fprintf(log_file, "Line no %d: Token <CONST_CHAR> Lexeme \'%s\' found --> <CONST_CHAR, %s>\n\n", line_count, yytext, escaped.c_str());    
                                string temp(yytext);
                                temp = "\'" + temp + "\'";
                                insert_to_symbol_table(temp, "CONST_CHAR");
                                BEGIN INITIAL;
                           }

<char_const>{MULTIPLE_CHAR} {
                                // Multiple characters, followed by closing '
                                // printf("%s", yytext);
                                if(strcmp(yytext, "\\\'") == 0) {
                                    fprintf(log_file, "Error at line no %d: Unterminated character \'\\\'\n\n\n", line_count);
                                    BEGIN INITIAL;
                                } else {
                                    int len = strlen(yytext);
                                    yytext[len-1] = '\0'; // Remove the closing '
                                    // fprintf(token_file, "<CHAR_CONST,%s> ", yytext);
                                    fprintf(log_file, "Error at line no %d: Multi character constant error \'%s\'\n\n\n", line_count, yytext);
                                    BEGIN INITIAL;
                                }
                                error_count++;

                            }   

<char_const>[\'] {
                    // Single quote without a character
                    // fprintf(token_file, "<CHAR_CONST,%s> ", yytext);
                    fprintf(log_file, "Error at line no %d: Empty character constant error \'\'\n\n\n", line_count);
                    BEGIN INITIAL;
                    error_count++;
                }

<char_const>{NEWLINE} {
                        // Newline inside character constant
                        // fprintf(token_file, "<CHAR_CONST,%s> ", yytext);
                        fprintf(log_file, "Error at line no %d: Unterminated character \'%s\n\n\n", line_count,character.c_str());
                        BEGIN INITIAL;
                        error_count++;
                        line_count++;
                      }

<char_const><<EOF>> {
                        // End of file inside character constant
                        // fprintf(token_file, "<CHAR_CONST,%s> ", yytext);
                        fprintf(log_file, "Error at line no %d: Unterminated character \'%s\n\n\n", line_count,character.c_str());
                        error_count++;
                        BEGIN INITIAL;
                    }    
<char_const>. {
                    character += yytext;
            }  

"\""    {
            BEGIN string_const;
            yytext[0] = '\0';
            str = "\"";
            str_for_log = "\"";
            str_start = line_count;
        }       

<string_const>{NEWLINE} { 
                            str += yytext;
                            str_for_log += yytext;
                            fprintf(log_file, "Error at line no %d: Unterminated string %s\n",str_start, str_for_log.c_str());
                            error_count++;
                            line_count++;
                            BEGIN INITIAL;        
                      }
<string_const><<EOF>> { 
                            str += yytext;
                            str_for_log += yytext;
                            fprintf(log_file, "Error at line no %d: Unterminated string %s\n",line_count, str_for_log.c_str());
                            error_count++;
                            BEGIN INITIAL;        
                      }


<string_const>\\\n {
                        // Backslash followed by newline
                        // str += "\\";
                        str_for_log += yytext;
                        line_count++;
                    }



<string_const>\\[ntafrbv0"] {
                            // Escaped character
                            escaped = escaped_character_token(yytext);
                            str += escaped;
                            str_for_log += yytext;
                          }
<string_const>\"    {
                        str.erase(0,1);
                        str_for_log += yytext;
                        fprintf(token_file, "<STRING, %s> ", str.c_str());
                        fprintf(log_file, "Line no %d: Token <STRING> Lexeme %s found --> <STRING, %s>\n\n", line_count, str_for_log.c_str(), str.c_str());
                        BEGIN INITIAL;
                    }
<string_const>. {
                    str += yytext;
                    str_for_log += yytext;
                }
"//"    {   
            cmnt = "//";
            BEGIN comment_single_line;
        }
<comment_single_line>[^\\\n]+   {
                                    cmnt += yytext;
                                }

<comment_single_line>\\\n   {
                                cmnt += "\\\n"; 
                                increment_line_count();
                            }

<comment_single_line>\n {
                            // End of comment
                            fprintf(log_file, "Line no %d: Token <COMMENT> Lexeme %s found\n\n", line_count, cmnt.c_str());
                            increment_line_count();
                            BEGIN INITIAL;
                        }

<comment_single_line><<EOF>>    {
                                    fprintf(log_file, "Line no %d: Token <COMMENT> Lexeme %s found\n\n", line_count, cmnt.c_str());
                                    BEGIN(INITIAL);
                                }

"/*"   {
            cmnt = "/*";
            BEGIN comment_multi_line;
            comment_start = line_count;
        }
<comment_multi_line>[^*\n]+     {
                                    cmnt += yytext;  // any normal text
                                }

<comment_multi_line>\n  {
                            cmnt += "\n";
                            increment_line_count();
                        }

<comment_multi_line>"*"+[^*/\n]*    {
                                        cmnt += yytext;  // handle stars not part of closing
                                    }

<comment_multi_line>"*/"    {
                                cmnt += yytext;  // handle closing  
                                fprintf(log_file, "Line no %d: Token <COMMENT> Lexeme %s found\n\n", line_count, cmnt.c_str());
                                BEGIN INITIAL;
                            }

<comment_multi_line><<EOF>> {
                                fprintf(log_file, "Error at line no %d: Unterminated comment %s\n\n\n", comment_start, cmnt.c_str());
                                BEGIN INITIAL;
                                error_count++;
                            }
.   {
        // Handle any other characters
        fprintf(log_file, "Error at line no %d: Unrecognized character %s\n\n", line_count, yytext);
        error_count++;
    }
%%

int main(int argc,char *argv[]){    
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin = fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	log_file = fopen("2105120_log.txt","w");
	token_file = fopen("2105120_token.txt","w");
    symbolTable.setLogFile(log_file);

	yyin= fin;
	yylex();
    final_print();
	fclose(yyin);
	fclose(token_file);
	fclose(log_file);
	return 0;
}
