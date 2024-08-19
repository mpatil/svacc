// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
%{

typedef real List[$]; 

typedef struct {	/* symbol table entry */
	string 		name; /* Name */
	shortint	type_;	/* VEC, VAR, BLTIN, UNDEF */
	real		val;	/* if VAR */
	List		vec;	/* if VEC */
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
	List	csvs;	/* comma seperated vals */ 
}
%token	<val>	NUMBER
%token	<sym>	VAR BLTIN UNDEF VEC
%type	<val>	expr asgn
%type	<csvs>	csvlist
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
	| VAR '=' '{' csvlist '}' { $$ = 0; $1.vec = $4; $1.type_ = `VEC; symlist[$1.name] = $1; }
	;
expr:	  NUMBER 
	| VAR {	if ($1.type_ == `UNDEF) execerror("undefined variable", $1.name); $$ = $1.val; }
	| VEC {	if ($1.type_ == `VEC) $$ = $1.vec.size(); }
	| VEC '[' expr ']'		{ $$ = $1.vec[int_($3)]; }
	| BLTIN '(' expr ')'	{ $$ = exec_bltin($1, $3); }
	| expr '+' expr			{ $$ = $1 + $3; }
	| expr '-' expr			{ $$ = $1 - $3; }
	| expr '*' expr			{ $$ = $1 * $3; }
	| expr '/' expr	{ if ($3 == 0.0) execerror("division by zero", ""); $$ = $1 / $3; }
	| expr '^' expr	{ $$ = pow($1, $3); }
	| '(' expr ')'	{ $$ = $2; }
	| '-' expr  %prec UNARYMINUS  { $$ = -$2; }
	;
csvlist:    /* nothing */  { List l; $$ = l; }
	| expr                 { List l; $$ = csvlist($1, l); }
	| csvlist ',' expr     { $$ = csvlist($3, $1); }
	;
%%
	/* end of grammar */
	string progname = "svc";
	int	lineno = 1;
	static Symbol symlist[string];  /* symbol table: linked list */

`include "init.sv"

	function shortint int_(real val);
		return real'(val);
	endfunction

	function List csvlist(real val, List list);        /* add formal to list */
		list.push_back(val);
		return list;
	endfunction

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
	function shortint yylex();		/* svc */
		while ((c=$fgetc(file)) == " " || c == "\t")
			;

		if (c == `EOF)
			return 0;

		if (c == "." || isdigit(c)) begin/* number */
			return numsym();
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

	function int numsym();
		typedef enum {_undet = 0, _int, _bin, _float, _hex} Fmt;
		Fmt fmt;
		string sel[Fmt];
		string sbuf;
		int i = 1;

		sbuf = {sbuf, string'(c)};

		if(c == ".")
			fmt = _float;
		else
			fmt = _undet;

		sel[_hex]	= "0123456789abcdefABCDEF";
		sel[_bin]	= "01";
		sel[_float]	= "0123456789eE-+";
		sel[_undet]	= "0123456789.xb";
		sel[_int]	= "0123456789";

		while(1) begin
			c = $fgetc(file);
			i++;
			if(c == `EOF)
				execerror("<eof> eating symbols", "");

			if(index(sel[fmt], string'(c)) == -1) begin
				r = $ungetc(c, file);
				i--;
				break;
			end

			sbuf = {sbuf, string'(c)};
			if (c ==".") 
				fmt = _float;
			else
				if (i == 2) begin
					case(sbuf)
						"0x": begin fmt = _hex; sbuf = ""; end
						"0b": begin fmt = _bin; sbuf = ""; end
					endcase
				end
		end

		if (fmt == _float && i == 1) begin
			r = $ungetc(sbuf[0], file);
			return -1;
		end
		else
		begin
			case (fmt)
				_float:		yylval.val = sbuf.atoreal(); 
				_bin:		yylval.val = real'(sbuf.atobin());
				_hex:		yylval.val = real'(sbuf.atohex()); 
				default:	yylval.val = real'(sbuf.atoi()); 
			endcase
		end
		return `NUMBER;
	endfunction

	static function int index(string s, string sub);
		int slen = s.len();
		int blen = sub.len();

		if ( slen == 0 || blen == 0 ) return -1;

		for ( int i = 0; i <= slen - blen + 1; i++ ) begin
			if ( s.substr( i, i + blen - 1 ) == sub )
				return i;
		end
      
		return -1;
	endfunction: index

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
