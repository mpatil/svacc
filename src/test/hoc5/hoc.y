// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
%{
`include "hoc.h"
`define	EOF	-1
typedef class Parser;
integer file = 0, r = 0;
string filename;
integer yydebug = 0;

import "DPI-C" pure function real sin (real rTheta);
import "DPI-C" pure function real cos (real rTheta);
import "DPI-C" pure function real atan (real rTheta);
import "DPI-C" pure function real log (real rVal);
import "DPI-C" pure function real log10 (real rVal);
import "DPI-C" pure function real exp (real rVal);
import "DPI-C" pure function real sqrt (real rVal);
import "DPI-C" pure function real abs (real rVal);
import "DPI-C" pure function real pow (real rVal1, real rVal2);

program automatic hoc;
	Parser p;
	initial begin : prog
        if ($value$plusargs("input=%s", filename)) 
			file = $fopen(filename, "r");
		if (file == 0) disable prog;
		p = new();
		$value$plusargs("yydebug=%0d", yydebug);
		p.yydebug = yydebug;
		p.init();
		p.initcode();
		while (p.yyparse()) begin
			p.execute(0);
			p.initcode();
		end
		$fclose(file);
	end
endprogram

class Parser;
%}
%union {
	Symbol	sym;	/* symbol table pointer */
	Inst	inst;	/* machine instruction */
}
%token	<sym>	NUMBER PRINT VAR BLTIN UNDEF WHILE IF ELSE
%type	<inst>	stmt asgn expr stmtlist cond while if end
%right	'='
%left	OR
%left	AND
%left	GT GE LT LE EQ NE
%left	'+' '-'
%left	'*' '/'
%left	UNARYMINUS NOT 
%right	'^'	/* exponentiation */
%%
list:	  /* nothing */
	| list '\n'
	| list asgn '\n'  { icode("pop"); icode("STOP"); return 1; }
	| list stmt '\n'  { icode("STOP"); return 1; }
	| list expr '\n'  { icode("print"); icode("STOP"); return 1; }
	;
asgn:	  VAR '=' expr	{ $$=$3; icode("varpush"); ocode($1); icode("assign"); }
	;
stmt:	  expr		{ icode("pop"); }
	| PRINT expr	{ icode("prexpr"); $$ = $2; }
	| while cond stmt end {
			pcode($1.ptr + 1, $3);	/* body of loop */
			pcode($1.ptr + 2, $4); }	/* end, if cond fails */
	| if cond stmt end {	/* else-less if */
			pcode($1.ptr + 1, $3);	/* thenpart */
			pcode($1.ptr + 3, $4); }	/* end, if cond fails */
	| if cond stmt end ELSE stmt end {  /* if with else */
			pcode($1.ptr + 1, $3);	/* thenpart */
			pcode($1.ptr + 2, $6);	/* elsepart */
			pcode($1.ptr + 3, $7); }	/* end, if cond fails */
	| '{' stmtlist '}'	{ $$ = $2; }
	;
cond:	  '(' expr ')'	{ icode("STOP"); $$ = $2; }
	;
while:	  WHILE	{ $$.ptr = icode("whilecode"); icode("STOP"); icode("STOP"); }
	;
if:	  IF	{ $$.ptr = icode("ifcode"); icode("STOP"); icode("STOP"); icode("STOP"); }
	;
end:	  /* nothing */		{ icode("STOP"); $$.ptr = progp; }
	;
stmtlist: /* nothing */		{ $$.ptr = progp; }
	| stmtlist '\n'
	| stmtlist stmt
	;
expr:	  NUMBER	{ $$.ptr = icode("constpush"); ocode($1); }
	| VAR		{ $$.ptr = icode("varpush"); ocode($1); icode("eval"); }
	| asgn
	| BLTIN '(' expr ')' { $$ = $3;icode("bltin"); ocode($1); }
	| '(' expr ')'	{ $$ = $2; }
	| expr '+' expr	{ icode("add"); }
	| expr '-' expr	{ icode("sub"); }
	| expr '*' expr	{ icode("mul"); }
	| expr '/' expr	{ icode("div"); }
	| expr '^' expr	{ icode("power"); }
	| '-' expr  %prec UNARYMINUS  { $$ = $2; icode("negate"); }
	| expr GT expr	{ icode("gt"); }
	| expr GE expr	{ icode("ge"); }
	| expr LT expr	{ icode("lt"); }
	| expr LE expr	{ icode("le"); }
	| expr EQ expr	{ icode("eq"); }
	| expr NE expr	{ icode("ne"); }
	| expr AND expr	{ icode("and"); }
	| expr OR expr	{ icode("or"); }
	| NOT expr	{ $$ = $2; icode("not"); }
	;
%%
	/* end of grammar */
	string progname = "hoc5";
	int	lineno = 1;
    static Symbol symlist[string];  /* symbol table: linked list */

`include "init.sv"
`include "code.sv"

	function bit isdigit(int c);
		return  (c >= "0" && c <= "9");
	endfunction

	function bit isalpha(int c);
		return ((c >= "a" && c <= "z") || (c >= "A" && c <= "Z"));
	endfunction

	function bit isalnum(int c);
		return (isalpha(c) || isdigit(c));
	endfunction

	static int c;	/* global for use by warning() */
	function shortint yylex();		/* hoc5 */

		while ((c=$fgetc(file)) == " " || c == "\t")
			;

		if (c == `EOF)
			return 0;

		if (c == "." || isdigit(c)) begin	/* number */
			Symbol s = new();
			real d;

			r = $ungetc(c, file);
			r = $fscanf(file, "%f", d);

			s.name = "";
			s.type_ = `NUMBER;
			s.val = d;

			yylval.sym = s;

			return `NUMBER;
		end

		if (isalpha(c)) begin 
			Symbol s;
			string sbuf;

			do begin
				sbuf = {sbuf, string'(c)};
				c = $fgetc(file);
			end while ((c != `EOF) && isalnum(c));
			r = $ungetc(c, file);

			if (symlist.exists(sbuf))
                s = symlist[sbuf];
			else  begin
				s = new();
				s.name = sbuf;
				s.type_ = `UNDEF;
				s.val = 0.0;
				symlist[sbuf] = s;
			end
			yylval.sym = s;
			return s.type_ == `UNDEF ? `VAR : s.type_;
		end

		case (c) 
			">":	return follow("=", `GE, `GT);
			"<":	return follow("=", `LE, `LT);
			"=":	return follow("=", `EQ, "=");
			"!":	return follow("=", `NE, `NOT);
			"|":	return follow("|", `OR, "|");
			"&":	return follow("&", `AND, "&");
			"\n":	begin lineno++; return "\n"; end
			default:	return c;
		endcase
	endfunction

	function shortint follow(shortint expect_, shortint ifyes, shortint ifno);  /* look ahead for >=, etc. */
		shortint c = $fgetc(file);

		if (c == expect_)
			return ifyes;
		r = $ungetc(c, file);
		return ifno;
	endfunction

	task yyerror(string s);
		warning(s, "");
	endtask

	task execerror(string s, string t);	/* recover from run-time error */
		warning(s, t);
		$finish;
	endtask

	task warning(string s, string t);
		$display("%s: %s", progname, s);
		if (t != "")
			$display(" %s", t);
		$display(" near line %0d\n", lineno);
		while (c != "\n" && c != `EOF)
			c = $fgetc(file);		/* flush rest of input line */
	endtask
endclass
