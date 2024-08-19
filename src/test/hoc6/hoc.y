// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
%{
`include "hoc.h"
`define	EOF	-1
typedef class Parser;
integer r = 0;
integer file_din = 0, file = 0;
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
		string filename, file_din_name;
        if ($value$plusargs("input=%s", filename)) 
			file = $fopen(filename, "r");
		if (file == 0) disable prog;
        if ($value$plusargs("data=%s", file_din_name)) 
			file_din = $fopen(file_din_name, "r");
		p = new();
		$value$plusargs("yydebug=%0d", yydebug);
		p.yydebug = yydebug;
		p.init();
		p.initcode();
		while (p.yyparse()) begin
			p.dump_prog();
			p.execute(p.progbase);
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
	int		narg;	/* number of arguments */
}
%token	<sym>	NUMBER STRING PRINT VAR BLTIN UNDEF WHILE IF ELSE
%token	<sym>	FUNCTION PROCEDURE RETURN FUNC PROC READ
%token	<narg>	ARG
%type	<inst>	expr stmt asgn prlist stmtlist
%type	<inst>	cond while if begin end 
%type	<sym>	procname
%type	<narg>	arglist
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
	| list defn '\n'
	| list asgn '\n'  { icode("pop"); icode("STOP"); return 1; }
	| list stmt '\n'  { icode("STOP"); return 1; }
	| list expr '\n'  { icode("print"); icode("STOP"); return 1; }
	| list error '\n' { $finish; }
	;
asgn:	  VAR '=' expr	{ $$=$3; icode("varpush"); ocode($1); icode("assign"); }
	| ARG '=' expr { defnonly("$"); icode("argassign"); ncode($1); $$=$3;}
	;
stmt:	  expr		{ icode("pop"); }
	| RETURN { defnonly("return"); icode("procret"); }
	| RETURN expr { defnonly("return"); $$=$2; icode("funcret"); }
	| PROCEDURE begin '(' arglist ')'
		{ $$ = $2; icode("call"); ocode($1); ncode($4); }
	| PRINT prlist	{ $$ = $2; }
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
begin:	  /* nothing */		{ $$.ptr = progp; }
	;
end:	  /* nothing */		{ icode("STOP"); $$.ptr = progp; }
	;
stmtlist: /* nothing */		{ $$.ptr = progp; }
	| stmtlist '\n'
	| stmtlist stmt
	;
expr:	  NUMBER	{ $$.ptr = icode("constpush"); ocode($1); }
	| VAR		{ $$.ptr = icode("varpush"); ocode($1); icode("eval"); }
	| ARG		{ defnonly("$"); $$.ptr = icode("arg"); ncode($1); }
	| asgn
	| FUNCTION begin '(' arglist ')'
		{ $$ = $2; icode("call");ocode($1);ncode($4); }
	| READ '(' VAR ')' { $$.ptr = icode("varread"); ocode($3); }
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
prlist:	  expr			{ icode("prexpr"); }
	| STRING		{ $$.ptr = icode("prstr"); ocode($1); }
	| prlist ',' expr	{ icode("prexpr"); }
	| prlist ',' STRING	{ icode("prstr"); ocode($3); }
	;
defn:	  FUNC procname { $2.type_=`FUNCTION; indef=1; }
	    '(' ')' stmt { icode("procret"); define($2); indef=0; }
	| PROC procname { $2.type_=`PROCEDURE; indef=1; }
	    '(' ')' stmt { icode("procret"); define($2); indef=0; }
	;
procname: VAR
	| FUNCTION
	| PROCEDURE
	;
arglist:  /* nothing */ 	{ $$ = 0; }
	| expr			{ $$ = 1; }
	| arglist ',' expr	{ $$ = $1 + 1; }
	;

%%
	/* end of grammar */
	string progname = "hoc6";
	int	lineno = 1;
    static Symbol symlist[string];  /* symbol table: linked list */
	int	indef;

`include "init.sv"
`include "code.sv"

	function bit isdigit(int c);
		return  (c >= "0" && c <= "9");
	endfunction

	function bit islower(int c);
		return  (c >= "a" && c <= "z");
	endfunction

	function bit isalpha(int c);
		return ((c >= "a" && c <= "z") || (c >= "A" && c <= "Z"));
	endfunction

	function bit isalnum(int c);
		return (isalpha(c) || isdigit(c));
	endfunction

	static int c;	/* global for use by warning() */
	function shortint yylex();		/* hoc6 */

		while ((c=$fgetc(file)) == " " || c == "\t")
			;

		if (c == `EOF)
			return 0;

		if (c == "." || isdigit(c)) begin	/* number */
			Symbol s = new();
			real d;

			r = $ungetc(c, file);
			r = $fscanf(file, "%f", d);

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
				symlist[sbuf] = s;
			end
			yylval.sym = s;
			return s.type_ == `UNDEF ? `VAR : s.type_;
		end
		if (c == "$") begin	/* argument? */
			int n = 0;
			c = $fgetc(file);
			while (isdigit(c)) begin
				n = 10 * n + c - "0";
				c = $fgetc(file);
			end
			r = $ungetc(c, file);
			if (n == 0)
				execerror("strange $...", "");
			yylval.narg = n;
			return `ARG;
		end
		if (c == "\"") begin	/* quoted string */
			string sbuf;
			Symbol s = new();
			for (c=$fgetc(file); c != "\""; c=$fgetc(file)) begin
				if (c == "\n" || c == `EOF)
					execerror("missing quote", "");
				sbuf = {sbuf, string'(backslash(c))};
			end	
			s.type_ = `STRING;
			s.sval = sbuf;

			yylval.sym = s;
			return `STRING;
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

	static function int index( string s, string sub);
		int slen = s.len();
		int blen = sub.len();

		if ( slen == 0 || blen == 0 ) return -1;

		for ( int i = 0; i <= slen - blen + 1; i++ ) begin
			if ( s.substr( i, i + blen - 1 ) == sub )
				return i;
		end
      
		return -1;
	endfunction: index

	function shortint backslash(shortint c);	/* get next char with \'s interpreted */
		string transtab = "b\bn\nr\rt\t";
		shortint idx;

		if (c != "\\")
			return c;
		c = $fgetc(file);
		idx = index(transtab, string'(c));
		if (islower(c) && -1 != idx)
			return transtab[idx + 1];
		return c;
	endfunction

	function shortint follow(shortint expect_, shortint ifyes, shortint ifno);  /* look ahead for >=, etc. */
		shortint c = $fgetc(file);

		if (c == expect_)
			return ifyes;
		r = $ungetc(c, file);
		return ifno;
	endfunction

	function void defnonly(string s);	/* warn if illegal definition */
		if (!indef)
			execerror(s, "used outside definition");
	endfunction

	task yyerror(string s);
		warning(s, "");
	endtask

	task execerror(string s, string t);	/* recover from run-time error */
		warning(s, t);
		$finish;
	endtask

	task warning(string s, string t);
		$write("%s: %s", progname, s);
		if (t != "")
			$write(" %s", t);
		$write(" near line %0d\n", lineno);
		while (c != "\n" && c != `EOF)
			c = $fgetc(file);		/* flush rest of input line */
		if (c == "\n")
			lineno++;
	endtask
endclass
