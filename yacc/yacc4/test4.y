%{
/*********************************************
YACC file
基础程序
Date:2023/9/19
forked SherryXiye
**********************************************/
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#define NSYMS 20

// 定义一个结构体用于存储符号表
struct symtab {
    char *name;     // 符号的名称
    double value;   // 符号的值
} symtab[NSYMS];    // 符号表的数组

// 函数声明：在符号表中查找符号
struct symtab *symlook(char *s);

char idStr[50];  // 用于存储标识符的字符数组
int yylex();    
extern int yyparse();  
FILE* yyin;    
void yyerror(const char* s);  

%}

// 共用体，读取用
%union {
    double dval;           
    struct symtab *symp;   
}

// 定义词法单元
%token ADD      
%token SUB
%token MUL
%token DIV
%token LEFTPAR
%token RIGHTPAR
%token <dval> NUMBER     // 数字
%token UMINUS           // 负号
%token equal            // 赋值符号
%token <symp> ID        // 标识符

// 定义运算符的结合性和优先级
%right equal
%left ADD SUB
%left MUL DIV
%right UMINUS
%left LEFTPAR RIGHTPAR

// 定义产生式的类型
%type <dval> expr

%%
lines    :    lines expr ';'    { printf("%f\n", $2); }  // 输出计算结果
        | lines ';'
        |
        ;

expr    : expr ADD expr { $$ = $1 + $3; }  // 加法表达式
        | expr SUB expr { $$ = $1 - $3; }  // 减法表达式
        | expr MUL expr { $$ = $1 * $3; }  // 乘法表达式
        | expr DIV expr { 
            if($3 == 0.0)
                yyerror("除零错误。");
            else
                $$ = $1 / $3; 
        }  // 除法表达式
        | LEFTPAR expr RIGHTPAR { $$ = $2; }  // 括号表达式
        | UMINUS expr %prec UMINUS { $$ = -$2; }  // 负号表达式
        | NUMBER { $$ = $1; }  // 数字
        | ID equal expr { $1->value=$3; $$=$3;}  // 赋值表达式
        | ID {$$=$1->value;}  // 变量表达式
        ;


%%
int isLastCharPram=0;// 区分符号和减号,不是在输入的第一个字符并且上一个字符是参数，返回减号。
int count=0;

// 词法分析器函数
int yylex()
{
    int t;
    count++;
    while (1)
    {
        t = getchar();
        if (t == ' ' || t == '\n' || t == '\t') { ; }
        else if (isdigit(t))
        {
            yylval.dval = 0;
            while (isdigit(t))
            {
                yylval.dval = yylval.dval * 10 + t - '0';
                t = getchar();
            }
            ungetc(t, stdin);
            isLastCharPram=0;
            return NUMBER;  // 返回数字词法单元
        }
        else if ((t>='a'&&t<='z')||(t>='A'&&t<='Z')||(t=='_'))
        {
            int ti=0;
            // 不可以数字开头
            while ((t>='a'&&t<='z')||(t>='A'&&t<='Z')||(t=='_')||(t>='0'&&t<='9'))
            {
                idStr[ti]=t;
                t = getchar();
                ti++;
            }
            idStr[ti]='\0';

            char* temp = (char*)malloc (50*sizeof(char)); 
            strcpy(temp,idStr);
            yylval.symp=symlook(temp); 

            ungetc(t, stdin);
            isLastCharPram=0;
            return ID;  // 返回标识符词法单元
        }
        else if (t == '-')
        {
            if(count!=1&&isLastCharPram==0)
            {
                return SUB;  // 返回减号词法单元
            }
            else
            {
                isLastCharPram=0;
                return UMINUS;  // 返回负号词法单元
            }
        } 
        else if (t == '(')
        {
            isLastCharPram=1;
            return LEFTPAR;  // 返回左括号词法单元
        }
        else if(t == ';')
        {
            count=0;
            return t;  // 返回分号词法单元
        }
        else if (t == '=')
        {
            isLastCharPram=0;
            return equal;  // 返回等号词法单元
        }
        else
        {
            isLastCharPram=0;
            if (t == '+') return ADD;  // 返回加号词法单元
            else if (t == '*') return MUL;  // 返回乘号词法单元
            else if (t == '/') return DIV;  // 返回除号词法单元
            else if (t == ')') return RIGHTPAR;  // 返回右括号词法单元
            else return t;
        }
    }
}

// 主函数
int main()
{
    yyin = stdin;
    do {
        yyparse();  // 解析输入的表达式
    } while (!feof(yyin));  // 直到文件结束

    return 0;
}

// 错误处理函数
void yyerror(const char* s) {
    fprintf(stderr, "解析错误: %s\n", s);
    exit(1);
}

// 在符号表中查找符号
struct symtab* symlook(char *s){
    char *p;
    struct symtab *sp;
    for(sp=symtab;sp<&symtab[NSYMS];sp++){
        if(sp->name && !strcmp(sp->name,s))
            return sp;  // 如果找到了同名的符号，则返回该符号的指针
        if(!sp->name){
            sp->name=strdup(s);  // 如果遍历到了空的符号项，则将新符号的名称复制过去
            return sp;
        }
    }
    yyerror("错误的输入");  // 如果符号表已满，则报错
    exit(1);
}

