// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
%{

typedef struct {	/* symbol table entry */
	string 		name; /* Name */
	shortint	type_;	/* VAR, BLTIN, UNDEF */
	real		val;	/* if VAR */
} Symbol;

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

program automatic svc;
	Parser p;
	initial begin : prog
        if ($value$plusargs("input=%s", filename)) 
			file = $fopen(filename, "r");
        if (file == 0) disable prog;
		p = new();
        $value$plusargs("yydebug=%0d", yydebug);
		p.yydebug = yydebug;
		p.init();
		p.yyparse();
        $fclose(file);
	end
endprogram

class Parser;
%}
%union {
	real	val;	/* actual value */
	Symbol	sym;	/* symbol table pointer */
}
%token	<val>	NUMBER
%token	<sym>	VAR BLTIN UNDEF
%type	<val>	expr asgn
%right	'='
%left	'+' '-'
%left	'*' '/'
%left	UNARYMINUS
%right	'^'	/* exponentiation */
%%
list:	  /* nothing */
	| list '\n'
	| list asgn '\n'
	| list expr '\n'	{ $display("\t%f\n", $2); }
	;
asgn:	  VAR '=' expr	{ $$ = $3; $1.val = $3; $1.type_ = `VAR; symlist[$1.name] = $1; }
	;
expr:	  NUMBER 
	| VAR {	if ($1.type_ == `UNDEF)
						execerror("undefined variable", $1.name);
				$$ = $1.val; }
	| asgn
	| BLTIN '(' expr ')'	{ $$ = exec_bltin($1, $3); }
	| expr '+' expr			{ $$ = $1 + $3; }
	| expr '-' expr			{ $$ = $1 - $3; }
	| expr '*' expr			{ $$ = $1 * $3; }
	| expr '/' expr	{
				if ($3 == 0.0)
					execerror("division by zero", "");
				$$ = $1 / $3; }
	| expr '^' expr	{ $$ = pow($1, $3); }
	| '(' expr ')'	{ $$ = $2; }
	| '-' expr  %prec UNARYMINUS  { $$ = -$2; }
	;
%%
	/* end of grammar */
	string progname = "svc";
	int	lineno = 1;
    static Symbol symlist[string];  /* symbol table: linked list */

`include "init.sv"

	function bit isdigit(int c);
		return  (c >= "0" && c <= "9");
	endfunction

	function bit isalpha(int c);
		return ((c >= "a" && c <= "z") || (c >= "A" && c <= "Z"));
	endfunction

	function bit isalnum(int c);
		return (isalpha(c) || isdigit(c));
	endfunction

	function shortint yylex();		/* svc */
		int c;

		while ((c=$fgetc(file)) == " " || c == "\t")
			;

		if (c == `EOF)
			return 0;

		if (c == "." || isdigit(c)) begin	/* number */
			r = $ungetc(c, file);
			r = $fscanf(file, "%f", yylval.val);
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

			if (symlist.exists(sbuf)) begin
                s = symlist[sbuf];
            end else begin
                s.name = sbuf;
                s.type_ = `UNDEF;
                s.val = 0.0;
				symlist[sbuf] = s;
            end
			yylval.sym = s;
			return s.type_ == `UNDEF ? `VAR : s.type_;
		end

		if (c == "\n")
			lineno++;
		return c;
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
	endtask
endclass
