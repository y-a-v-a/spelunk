grammar TauCore;

// ----------------------
// PARSER RULES
// ----------------------

compilationUnit
  : NEWLINE*
    modDecl? NEWLINE*
    (useDecl (NEWLINE+ useDecl)*)? NEWLINE*
    (topLevelDecl (NEWLINE+ topLevelDecl)*)?
    NEWLINE* EOF
  ;

topLevelDecl
  : typeDecl
  | fnDecl
  | testDecl
  ;

modDecl
  : MOD ID
  ;

useDecl
  : USE importPath
  ;

importPath
  : ID (DOUBLE_COLON ID)*
  ;

// ---------- Types ----------

typeDecl
  : TYPE TYPE_ID typeParams? ASSIGN sumOrProductType
  ;

typeParams
  : LT TYPE_ID (COMMA TYPE_ID)* GT
  ;

sumOrProductType
  : productType
  | sumType
  ;

productType
  : LBRACE fieldList? RBRACE
  ;

fieldList
  : field (COMMA field)*
  ;

field
  : ID COLON typeRef
  ;

sumType
  : variant (PIPE variant)*
  ;

variant
  : TYPE_ID (LPAREN typeList? RPAREN)?
  ;

typeList
  : typeRef (COMMA typeRef)*
  ;

typeRef
  : simpleType (LT typeList GT)?
  ;

simpleType
  : TYPE_ID
  | I32
  | I64
  | F32
  | F64
  | BOOL
  | STR
  ;

// ---------- Functions & tests ----------

fnDecl
  : FN ID LPAREN paramList? RPAREN COLON typeRef ASSIGN NEWLINE fnBody
  ;

paramList
  : param (COMMA param)*
  ;

param
  : ID COLON typeRef
  ;

fnBody
  : NEWLINE* stmt (NEWLINE+ stmt)* NEWLINE*
  ;

testDecl
  : TEST ID ASSIGN NEWLINE fnBody
  ;

// ---------- Statements ----------

stmt
  : declStmt
  | assignStmt
  | returnStmt
  | guardStmt
  | matchStmt
  | panicStmt
  | exprStmt
  ;

declStmt
  : ID (BANG)? COLON typeRef ASSIGN expr
  ;

assignStmt
  : ID (BANG)? ASSIGN expr
  ;

returnStmt
  : CARET expr
  ;

panicStmt
  : PANIC BANG
  ;

// cond ? action
guardStmt
  : expr QUESTION guardAction
  ;

guardAction
  : returnStmt
  | assignStmt
  | panicStmt
  | expr
  ;

// r | Ok(_) -> action
matchStmt
  : expr PIPE pattern ARROW guardAction (NEWLINE PIPE pattern ARROW guardAction)+
  ;

exprStmt
  : expr
  ;

// ---------- Patterns ----------

pattern
  : UNDERSCORE                         # WildcardPattern
  | ID                                  # VarPattern
  | TYPE_ID LPAREN patternList? RPAREN  # CtorPattern
  ;

patternList
  : pattern (COMMA pattern)*
  ;

// ---------- Expressions (precedence climbing) ----------

expr
  : orExpr
  ;

orExpr
  : andExpr (OROR andExpr)*
  ;

andExpr
  : equalityExpr (ANDAND equalityExpr)*
  ;

equalityExpr
  : relationalExpr ((EQEQ | NEQ) relationalExpr)*
  ;

relationalExpr
  : additiveExpr ((LT | LE | GT | GE) additiveExpr)*
  ;

additiveExpr
  : multiplicativeExpr ((PLUS | MINUS) multiplicativeExpr)*
  ;

multiplicativeExpr
  : unaryExpr ((STAR | SLASH) unaryExpr)*
  ;

unaryExpr
  : (PLUS | MINUS | BANG) unaryExpr
  | primary
  ;

// Primary / suffix structure

primary
  : literal
  | ID suffix*
  | TYPE_ID ctorSuffix
  | LPAREN expr RPAREN
  ;

suffix
  : LPAREN argList? RPAREN         // function call: f(...)
  | DOT ID                         // field access: x.y
  ;

ctorSuffix
  : DOT LPAREN argList? RPAREN     // Ok.(x)  -> Ok(x)
  | DOT STRING                     // Err."msg" -> Err("msg")
  | DOT LBRACE fieldInitList? RBRACE // Type.{ x:1, y:2 }
  ;

argList
  : expr (COMMA expr)*
  ;

fieldInitList
  : fieldInit (COMMA fieldInit)*
  ;

fieldInit
  : ID COLON expr
  ;

literal
  : INT
  | FLOAT
  | STRING
  | TRUE
  | FALSE
  ;

// ----------------------
// LEXER RULES
// ----------------------

// Keywords

MOD     : 'mod';
USE     : 'use';
TYPE    : 'type';
FN      : 'fn';
TEST    : 'test';

PANIC   : 'panic';

TRUE    : 'true';
FALSE   : 'false';

I32     : 'i32';
I64     : 'i64';
F32     : 'f32';
F64     : 'f64';
BOOL    : 'bool';
STR     : 'str';

// Operators / punctuation

DOUBLE_COLON : '::';
ARROW        : '->';

ASSIGN  : '=';
COLON   : ':';
COMMA   : ',';

LPAREN  : '(';
RPAREN  : ')';
LBRACE  : '{';
RBRACE  : '}';

DOT     : '.';
LT      : '<';
GT      : '>';
PLUS    : '+';
MINUS   : '-';
STAR    : '*';
SLASH   : '/';

QUESTION: '?';
PIPE    : '|';
BANG    : '!';
CARET   : '^';

EQEQ    : '==';
NEQ     : '!=';
LE      : '<=';
GE      : '>=';

ANDAND  : '&&';
OROR    : '||';

// Identifiers & literals

UNDERSCORE : '_';

TYPE_ID : [A-Z] [a-zA-Z0-9_]*;
ID      : [a-z_] [a-zA-Z0-9_]*;

INT     : [0-9]+;
FLOAT   : [0-9]+ '.' [0-9]+;

STRING  : '"' ( ~["\\] | '\\' . )* '"';

// Whitespace & comments

NEWLINE
  : '\r'? '\n'+
  ;

WS
  : [ \t\r]+ -> skip
  ;

LINE_COMMENT
  : '//' ~[\r\n]* -> skip
  ;

BLOCK_COMMENT
  : '/*' .*? '*/' -> skip
  ;
