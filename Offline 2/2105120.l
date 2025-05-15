%option noyywrap

%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>

int line_count=1;

void increment_line_count(){
    line_count++;
}

FILE *log_file;
FILE *token_file;

void write_log(const char *token, const char *lexeme){
    fprintf(log_file, "Line No. %d: Token %s Lexeme %s found.\n", line_count, token, lexeme);
}

void write_token(const char *token) {
    fprintf(token_file, "%s ", token);
}

void write_log_token(const char *token,const char *lexeme){
    write_log(token, lexeme);
    write_token(token);
}

%}

WHITESPACE [ \t\f\r\v]+ 
DIGIT [0-9]
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
        sprintf(token, "<ADDOP,%s>", yytext);
        write_log_token(token, yytext);
    }

"*" |
"/" |
"%" {
        char token[16];
        sprintf(token, "<MULOP,%s>", yytext);
        write_log_token(token, yytext);
    }

"++" |
"--" {
        char token[16];
        sprintf(token, "<INCOP,%s>", yytext);
        write_log_token(token, yytext);
     }

"=" {   
        write_log_token("<ASSIGNOP,=>", yytext);
    }

"&&" |
"||" {
        char token[16];
        sprintf(token, "<LOGICOP,%s>", yytext);
        write_log_token(token, yytext);
     }

"!" {
        write_log_token("<NOT,!>", yytext);
    }

"<" |
">" |
"<=" |
">=" |
"==" |
"!=" {
        char token[16];
        sprintf(token, "<RELOP,%s>", yytext);
        write_log_token(token, yytext);
     }

"(" {
        write_log_token("<LPAREN,(>", yytext);
    }

")" {
        write_log_token("<RPAREN,)>", yytext);
    }

"{" {
        write_log_token("<LCURL,{>", yytext);
    }

"}" {
        write_log_token("<RCURL,}>", yytext);
    }

"[" {
        write_log_token("<LTHIRD,[>", yytext);
    }

"]" {
        write_log_token("<RTHIRD,]>", yytext);
    }

"," {
        write_log_token("<COMMA,,>", yytext);
    }

";" {
        write_log_token("<SEMICOLON,;>", yytext);
    }

{IDENTIFIER}    {   
                    char token[100];
                    sprintf(token, "<ID,%s>", yytext);
                    write_log_token(token, yytext);  
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
