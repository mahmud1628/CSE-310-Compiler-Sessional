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

int line_count=1;
string str,cmnt,escaped;

SymbolTable symbolTable = SymbolTable(7);

void increment_line_count(){
    line_count++;
}

string escaped_character_token(const char *text) {
    string s(text);
    if(s == "\\n") {
        return "\n";
    } else if(s == "\\t") {
        return "\t";
    } else if(s == "\\r") {
        return "\r";
    } else if(s == "\\f") {
        return "\f";
    } else if(s == "\\a") {
        return "\a";
    } else if(s == "\\b") {
        return "\b";
    } else if(s == "\\v") {
        return "\v";
    } else if(s == "\\0") {
        return "\0";
    } else if(s == "\\\"") {
        return "\"";
    }
    // } else if(s == "\\'") {
    //     return "\'";
    // } else if(s == "\\\"") {
    //     return "\"";
    // } else if(s == "\\\\") {
    //     return "\\";
    // }
    return s; // Return the original string if no match found
}

FILE *log_file;
FILE *token_file;

void write_log(const char *token, const char *lexeme){
    fprintf(log_file, "Line No. %d: Token %s Lexeme %s found.\n\n", line_count, token, lexeme);
}

void write_token(const char *token) {
    fprintf(token_file, "%s ", token);
}

void write_log_token(const char *token,const char *lexeme){
    write_log(token, lexeme);
    write_token(token);
}

void insert_to_symbol_table(const char * name, const string & type) {
    string n(name);
    symbolTable.insert(n, type);
    symbolTable.printAllScopes(log_file);
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
        char token[16];
        sprintf(token, "<ADDOP, %s>", yytext);
        write_log_token(token, yytext);
    }

"*" |
"/" |
"%" {
        char token[16];
        sprintf(token, "<MULOP, %s>", yytext);
        write_log_token(token, yytext);
    }

"++" |
"--" {
        char token[16];
        sprintf(token, "<INCOP, %s>", yytext);
        write_log_token(token, yytext);
     }

"=" {   
        write_log_token("<ASSIGNOP, =>", yytext);
    }

"&&" |
"||" {
        char token[16];
        sprintf(token, "<LOGICOP, %s>", yytext);
        write_log_token(token, yytext);
     }

"!" {
        write_log_token("<NOT, !>", yytext);
    }

"<" |
">" |
"<=" |
">=" |
"==" |
"!=" {
        char token[16];
        sprintf(token, "<RELOP, %s>", yytext);
        write_log_token(token, yytext);
     }

"(" {
        write_log_token("<LPAREN, (>", yytext);
    }

")" {
        write_log_token("<RPAREN, )>", yytext);
    }

"{" {   
        symbolTable.enterScope();
        write_log_token("<LCURL, {>", yytext);
    }

"}" {   
        symbolTable.exitScope();
        write_log_token("<RCURL, }>", yytext);
    }

"[" {
        write_log_token("<LTHIRD, [>", yytext);
    }

"]" {
        write_log_token("<RTHIRD, ]>", yytext);
    }

"," {
        write_log_token("<COMMA, ,>", yytext);
    }

";" {
        write_log_token("<SEMICOLON, ;>", yytext);
    }

{IDENTIFIER}    {   
                    fprintf(token_file, "<ID, %s> ", yytext);
                    fprintf(log_file, "Line No %d: Token <ID> Lexeme %s found\n\n", line_count, yytext);
                    insert_to_symbol_table(yytext, "ID");
                }

{CONST_INT}     {   
                    string name(yytext);
                    symbolTable.insert(name, "CONST_INT");
                    fprintf(token_file, "<CONST_INT, %s> ", yytext);
                    fprintf(log_file, "Line No. %d: Token <CONST_INT,%s> Lexeme %s found.\n", line_count, yytext, yytext);
                }

{TOO_MANY_DECIMAL_POINTS}   {
                                // Handle error for too many decimal points
                                fprintf(log_file, "Error at line no %d: Too many decimal points in constant %s\n", line_count, yytext);
                            }


{CONST_FLOAT}   {
                    string name(yytext);
                    symbolTable.insert(name, "CONST_FLOAT");
                    fprintf(token_file, "<CONST_FLOAT, %s> ", yytext);
                    fprintf(log_file, "Line No. %d: Token <CONST_FLOAT,%s> Lexeme %s found.\n", line_count, yytext, yytext);
                }

{ILL_FORMED_NUMBER}     {
                            // Handle error for ill-formed number
                            fprintf(log_file, "Error at line no %d: Ill-formed number %s\n", line_count, yytext);
                        }

{DIGIT}+{IDENTIFIER}+   {
                            // Handle error for identifier starting with digit
                            fprintf(log_file, "Error at line no %d: Invalid Suffix on numeric constant or invalid prefix on identifier %s\n", line_count, yytext);
                        }

"\'"    {
            BEGIN char_const;
            yytext[0] = '\0';
        }


<char_const>{SINGLE_CHAR} {
                            // Single character, followed by closing '
                            int len = strlen(yytext);
                            yytext[len-1] = '\0'; // Remove the closing '
                            string name(yytext);
                            symbolTable.insert(name, "CONST_CHAR");
                            fprintf(token_file, "<CONST_CHAR, %s> ", yytext);
                            fprintf(log_file, "Line No. %d: Token <CHAR_CONST,%s> Lexeme %s found.\n", line_count, yytext, yytext);
                            BEGIN INITIAL;
                        }

<char_const>{ESCAPED_CHAR} {
                                // Escaped character, followed by closing '
                                int len = strlen(yytext);
                                yytext[len-1] = '\0'; // Remove the closing '
                                // fprintf(token_file, "<CONST_CHAR, %s> ", yytext);
                                escaped = escaped_character_token(yytext);
                                // cout << escaped << endl;
                                string name(escaped);
                                symbolTable.insert(name, "CONST_CHAR");
                                fprintf(token_file, "<CONST_CHAR, %s> ", escaped.c_str());
                                fprintf(log_file, "Line No. %d: Token <CHAR_CONST,%s> Lexeme %s found.\n", line_count, yytext, yytext);
                                BEGIN INITIAL;
                           }

<char_const>{MULTIPLE_CHAR} {
                                // Multiple characters, followed by closing '
                                // printf("%s", yytext);
                                if(strcmp(yytext, "\\\'") == 0) {
                                    fprintf(log_file, "Error at line no. %d: Missing terminating \' character \n", line_count);
                                    BEGIN INITIAL;
                                } else {
                                    int len = strlen(yytext);
                                    yytext[len-1] = '\0'; // Remove the closing '
                                    // fprintf(token_file, "<CHAR_CONST,%s> ", yytext);
                                    fprintf(log_file, "Error at line no. %d: Multi-character character constant \'%s\'\n", line_count, yytext);
                                    BEGIN INITIAL;
                                }

                            }   

<char_const>[\'] {
                    // Single quote without a character
                    // fprintf(token_file, "<CHAR_CONST,%s> ", yytext);
                    fprintf(log_file, "Error at line no. %d: Empty character constant \n", line_count);
                    BEGIN INITIAL;
                }

<char_const>{NEWLINE} {
                        // Newline inside character constant
                        // fprintf(token_file, "<CHAR_CONST,%s> ", yytext);
                        fprintf(log_file, "Error at line no. %d: Missing terminating \' character \n", line_count);
                        BEGIN INITIAL;
                      }

<char_const><<EOF>> {
                        // End of file inside character constant
                        // fprintf(token_file, "<CHAR_CONST,%s> ", yytext);
                        fprintf(log_file, "Error at line no. %d: Missing terminating \' character \n", line_count);
                        BEGIN INITIAL;
                    }      

"\""    {
            BEGIN string_const;
            yytext[0] = '\0';
            str = "\"";
        }       

<string_const>{NEWLINE} |
<string_const><<EOF>> { 
                            str += yytext;
                            fprintf(log_file, "Error at line no %d: Unterminated string %s\n",line_count, str.c_str());
                            BEGIN INITIAL;        
                      }

<string_const>\\\n {
                        // Backslash followed by newline
                        // str += "\\";
                        line_count++;
                    }

<string_const>[\\\n] {
                        // Backslash followed by newline
                        str += "\n";
                     }

<string_const>\\[tafrbv0"] {
                            // Escaped character
                            escaped = escaped_character_token(yytext);
                            str += escaped;
                          }
<string_const>\"    {
                        str.erase(0,1);
                        string name(str);
                        symbolTable.insert(name, "STRING");
                        fprintf(token_file, "<STRING, %s> ", str.c_str());
                        fprintf(log_file, "Line no %d: Token <STRING> Lexeme \"%s\" found\n", line_count, str.c_str());
                        BEGIN INITIAL;
                    }
<string_const>. {
                    str += yytext;
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
                            fprintf(log_file, "Line no %d: Token <COMMENT> Lexeme %s found\n", line_count, cmnt.c_str());
                            increment_line_count();
                            BEGIN INITIAL;
                        }

<comment_single_line><<EOF>>    {
                                    fprintf(log_file, "Line no %d: Token <COMMENT> Lexeme %s found\n", line_count, cmnt.c_str());
                                    BEGIN(INITIAL);
                                }

"/*"   {
            cmnt = "/*";
            BEGIN comment_multi_line;
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
                                fprintf(log_file, "Line no %d: Token <COMMENT> Lexeme %s found\n", line_count, cmnt.c_str());
                                BEGIN INITIAL;
                            }

<comment_multi_line><<EOF>> {
                                fprintf(log_file, "Line No. %d: Error - Unterminated comment %s", line_count, cmnt.c_str());
                                BEGIN INITIAL;
                            }
.   {
        // Handle any other characters
        fprintf(log_file, "Error at line no %d: Unrecognized character %s\n", line_count, yytext);
    }
%%

int main(int argc,char *argv[]){    
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	log_file= fopen("log.txt","w");
	token_file= fopen("token.txt","w");

	yyin= fin;
	yylex();
	fclose(yyin);
	fclose(token_file);
	fclose(log_file);
	return 0;
}
