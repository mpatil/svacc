// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
%{
`include "hoc.h"
`define	EOF	-1
typedef class Parser;
integer r = 0;
integer file_din = 0, file = 0;

import "DPI-C" pure function real sin (real rTheta);
import "DPI-C" pure function real cos (real rTheta);
import "DPI-C" pure function real tan (real rTheta);
import "DPI-C" pure function real asin (real rTheta);
import "DPI-C" pure function real acos (real rTheta);
import "DPI-C" pure function real atan (real rTheta);
import "DPI-C" pure function real sinh (real rTheta);
import "DPI-C" pure function real cosh (real rTheta);
import "DPI-C" pure function real tanh (real rTheta);
import "DPI-C" pure function real exp (real rVal);
import "DPI-C" pure function real abs (real rVal);
import "DPI-C" pure function real fabs (real rVal);
import "DPI-C" pure function real log (real rVal);
import "DPI-C" pure function real log10 (real rVal);
import "DPI-C" pure function real pow (real rVal1, real rVal2);
import "DPI-C" pure function real sqrt (real rVal);
import "DPI-C" pure function real round (real rVal);
import "DPI-C" pure function real ceil (real rVal);
import "DPI-C" pure function real floor (real rVal);

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
		p.run_();
		$fclose(file);
	end
endprogram

`define	LINENOPP begin lineno++; lineoff = $ftell(file); end
`define icode(x) Process::icode(x)
`define ocode(x) Process::ocode(x)
`define ncode(x) Process::ncode(x)
`define pcode(x, y) Process::pcode((x), (y))
`define progp	Process::progp

class Parser;
	typedef class Process;
%}
%union {
	Symbol	sym;		/* symbol table pointer */
	Inst	inst;		/* machine instruction */
	int		narg;		/* number of arguments */
	Args	formals;	/* list of formal parameters */
}
%token	<sym>		NUMBER STRING PRINT VAR BLTIN UNDEF WHILE IF ELSE
%token	<sym>		FUNCTION PROCEDURE RETURN FUNC PROC READ
%token	<sym>		FOR CASE DEFAULT BREAK VEC VECTOR FORK
%type	<formals>	formals
%type	<inst>		expr stmt asgn prlist stmtlist break
%type	<inst>		for case cases case_expr case_stmt case_def
%type	<inst>		cond while if begin end vecvar fork forks fork_stmt fork_begin
%type	<sym>		procname
%type	<narg>		arglist
%right	'='
%left	OR
%left	AND
%left	GT GE LT LE EQ NE
%right	AE SE ME DE MME     /* += -= *= /= %= */
%left	'+' '-'
%left	'*' '/' '%'
%left	UNARYMINUS NOT PP MM 
%right	'^'	/* exponentiation */
%%
list:	/* nothing */
	| list '\n'
	| list defn '\n'
	| list asgn '\n'	{ `icode("pop"); `icode("STOP"); return 1; }
	| list stmt '\n'	{ `icode("STOP"); return 1; }
	| list expr '\n'	{ `icode("print"); `icode("STOP"); return 1; }
	| list error '\n'	{ $finish; }
	;
asgn:	VAR '=' expr	{ $$=$3; `icode("varpush"); `ocode($1); `icode("assign"); }
	| vecvar '=' expr	{ $$=$3; `icode("vecassign"); }
	| VAR AE expr	{ $$=$3; `icode("varpush"); `ocode($1); `icode("addeq"); }
	| VAR SE expr	{ $$=$3; `icode("varpush"); `ocode($1); `icode("subeq"); }
	| VAR ME expr	{ $$=$3; `icode("varpush"); `ocode($1); `icode("muleq"); }
	| VAR DE expr	{ $$=$3; `icode("varpush"); `ocode($1); `icode("diveq"); }
	| VAR MME expr	{ $$=$3; `icode("varpush"); `ocode($1); `icode("modeq"); }
	;
stmt:	expr		{ `icode("pop"); }
	| RETURN		{ defnonly("return"); `icode("procret"); }
	| RETURN expr	{ defnonly("return"); $$=$2; `icode("funcret"); }
	| PROCEDURE begin '(' arglist ')' { $$ = $2; `icode("call"); `ocode($1); `ncode($4); }
	| PRINT prlist	{ $$ = $2; }
	| BREAK break	{ $$ = $2; }
	| '#' expr		{ `icode("waitcode"); }
	| fork '{' forks '}' end { /* fork */
				`pcode($1.ptr + 1, $5); }	/* end */
	| case '(' cond ')' '{' cases case_def '}' end { /* case */
				`pcode($1.ptr + 1, $6);		/* first case entry */
				`pcode($1.ptr + 2, $7);		/* default case entry */
				`pcode($1.ptr + 3, $9);	}	/* end */
	| while '(' cond ')' stmt end {	/* while */
				`pcode($1.ptr + 1, $5);		/* body of loop */
				`pcode($1.ptr + 2, $6); }	/* end, if cond fails */
	| for {infor = 1; } '(' cond ';' cond ';' cond ')' {infor = 0; } stmt end {	/* for */
				`pcode($1.ptr + 1, $6);     /* condition */
				`pcode($1.ptr + 2, $8);     /* post loop */
				`pcode($1.ptr + 3, $11);     /* body of loop */
				`pcode($1.ptr + 4, $12); }  /* end, if cond fails */

	| if '(' cond ')' stmt end {	/* else-less if */
				`pcode($1.ptr + 1, $5);		/* thenpart */
				`pcode($1.ptr + 3, $6); }	/* end, if cond fails */
	| if '(' cond ')' stmt end ELSE stmt end {  /* if with else */
				`pcode($1.ptr + 1, $5);		/* thenpart */
				`pcode($1.ptr + 2, $8);		/* elsepart */
				`pcode($1.ptr + 3, $9); }	/* end, if cond fails */
	| VECTOR vecvar  { $$ = $2; `icode("decvec"); }
	| '{' stmtlist '}'	{ $$ = $2; }
	;
cond:	expr	{ `icode("STOP"); }
	;
fork:	FORK	{ $$.ptr = `icode("forkcode"); `icode("STOP"); }
	;
forks: /* nothing */ '\n' 	{ $$.ptr = `progp; }
	| fork_begin fork_stmt '\n' {  `pcode($1.ptr - 1, $2); }
	| forks fork_begin fork_stmt {  `pcode($2.ptr - 1, $3); }
	;
fork_begin: {  `icode("STOP21"); $$.ptr = `progp; }
	;
fork_stmt: stmt '\n' { `icode("STOP"); $$.ptr=`progp; }
	;
case:	CASE { $$.ptr = `icode("casecode"); `icode("STOP"); `icode("STOP"); `icode("STOP"); }
	;
cases: /* nothing */   '\n'			{ $$.ptr = `progp; `icode("STOP"); }
	| case_expr case_stmt '\n'		{ `pcode($1.ptr - 1, $2); `icode("STOP"); }
	| cases case_expr case_stmt 	{ `pcode($2.ptr - 1, $3); `icode("STOP"); }
	;
case_expr: expr { `icode("STOP"); }
	;
case_stmt: ':' stmt	'\n'	{  `icode("STOP"); $$.ptr=`progp; }
	;
case_def: /* nothing */ { $$.ptr = `progp; `icode("STOP");}
	| { $$.ptr = `progp; } DEFAULT case_stmt	{ `icode("STOP"); }
	;
vecvar:	VAR '[' expr ']' /* for vector declaration */ { `icode("varpush"); `ocode($1); }
	| VEC '[' expr ']' { `icode("varpush"); `ocode($1); }
	;
while:	WHILE	{ $$.ptr = `icode("whilecode"); `icode("STOP"); `icode("STOP"); }
	;
for:	FOR	{ $$.ptr = `icode("forcode"); `icode("STOP"); `icode("STOP"); `icode("STOP"); `icode("STOP");}
	;
if:		IF	{ $$.ptr = `icode("ifcode"); `icode("STOP"); `icode("STOP"); `icode("STOP"); }
	;
begin:	/* nothing */	{ $$.ptr = `progp; }
	;
end:	/* nothing */	{ `icode("STOP"); $$.ptr = `progp; }
	;
break:	/* nothing */ { $$.ptr = `icode("break"); }
	;
stmtlist: /* nothing */		{ $$.ptr = `progp; }
	| stmtlist '\n'
	| stmtlist stmt
	;
expr:	NUMBER	{ $$.ptr = `icode("constpush"); `ocode($1); }
	| VAR		{ $$.ptr = `icode("varpush"); `ocode($1); `icode("eval"); }
	| vecvar	{ `icode("eval"); }
	| asgn
	| FUNCTION begin '(' arglist ')' { $$ = $2; `icode("call");`ocode($1);`ncode($4); }
	| READ '(' VAR ')' { $$.ptr = `icode("varread"); `ocode($3); }
	| BLTIN '(' expr ')' { $$ = $3;`icode("bltin"); `ocode($1); }
	| '(' expr ')'	{ $$ = $2; }
	| expr '+' expr	{ `icode("add"); }
	| expr '-' expr	{ `icode("sub"); }
	| expr '*' expr	{ `icode("mul"); }
	| expr '/' expr	{ `icode("div"); }
	| expr '%' expr { `icode("mod"); }
	| expr '^' expr	{ `icode("power"); }
	| '-' expr  %prec UNARYMINUS  { $$ = $2; `icode("negate"); }
	| expr GT expr	{ `icode("gt"); }
	| expr GE expr	{ `icode("ge"); }
	| expr LT expr	{ `icode("lt"); }
	| expr LE expr	{ `icode("le"); }
	| expr EQ expr	{ `icode("eq"); }
	| expr NE expr	{ `icode("ne"); }
	| expr AND expr	{ `icode("and"); }
	| expr OR expr	{ `icode("or"); }
	| NOT expr		{ $$ = $2; `icode("not"); }
	| PP VAR		{ /* process ++ increment */  $$.ptr = `icode("preinc"); `ocode($2); }
	| MM VAR		{ /* process -- decrement */  $$.ptr = `icode("predec"); `ocode($2); }
	| VAR PP		{ /* process ++ increment */  $$.ptr = `icode("postinc"); `ocode($1); }
	| VAR MM		{ /* process -- decrement */  $$.ptr = `icode("postdec"); `ocode($1); }
	;
prlist:	expr			{ `icode("prexpr"); }
	| STRING			{ $$.ptr = `icode("prstr"); `ocode($1); }
	| prlist ',' expr	{ `icode("prexpr"); }
	| prlist ',' STRING	{ `icode("prstr"); `ocode($3); }
	;
defn:	FUNC procname	{ $2.type_=`FUNCTION; indef=1; }
	    '(' formals ')' stmt { `icode("procret"); Process::define($2, $5); indef=0; }
	| PROC procname		{ $2.type_=`PROCEDURE; indef=1; }
	    '(' formals ')' stmt { `icode("procret"); Process::define($2, $5); indef=0; }
	;
formals:	/* nothing */	{ Args f; $$ = f; /*$$ = 0;*/ }
	| VAR					{ Args f; $$ = formallist($1, f); }
	| VAR ',' formals		{ $$ = formallist($1, $3); }
	;
procname: VAR
	| FUNCTION
	| PROCEDURE
	;
arglist:	/* nothing */	{ $$ = 0; }
	| expr					{ $$ = 1; }
	| arglist ',' expr		{ $$ = $1 + 1; }
	;

%%
	/* end of grammar */
	static string progname = "hoc7";
	static int	indef, infor;
	static int	lineno = 1, lineoff = 1;

`include "code.sv"
`include "init.sv"

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
	function shortint yylex();		/* hoc7 */

		eat_whitespace();

		if (c == `EOF)
			return 0;

		if (c == "\\") begin /* line continuation */
			if ((c = $fgetc(file)) == "\n") begin
				`LINENOPP
				return yylex();
			end
		end

		if (c == "/") begin         /* possible comment */
			shortint c_ = $fgetc(file);
			case(c_)
				"/": begin
						if ((c_ = $fgetc(file)) == "*")
							r = $fseek(file, -2, 1);
						else begin
							r = $ungetc(c_, file);
							while ((c_=$fgetc(file)) != "\n" && c_ >= 0)
								;
							if (c_ == "\n")
								`LINENOPP
							return c_;
						end
					end
				"*": begin
						skipcomment();
						return yylex();
					end
				default: r = $ungetc(c_, file);
			endcase
		end

		if (c == "." || isdigit(c)) begin	/* number */
			Symbol s = new();
			real d;

			r = $ungetc(c, file);
			r = $fscanf(file, "%f", d);

			s.type_ = `NUMBER;
			s.u.val = d;

			yylval.sym = s;

			return `NUMBER;
		end

		if (isalpha(c) ||  c == "_") begin 
			Symbol s;
			string sbuf;

			do begin
				sbuf = {sbuf, string'(c)};
				c = $fgetc(file);
			end while ((c != `EOF) && (isalnum(c) || c == "_"));
			r = $ungetc(c, file);

			if (Process::symlist.exists(sbuf))
                s = Process::symlist[sbuf];
			else  begin
				s = new();
				s.name = sbuf;
				s.type_ = `UNDEF;
				Process::symlist[sbuf] = s;
			end
			yylval.sym = s;
			return s.type_ == `UNDEF ? `VAR : s.type_;
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
			s.u.sval = sbuf;

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
			"+":	return follow("+",`PP, follow("=",`AE,"+"));
			"-":	return follow("-",`MM, follow("=",`SE,"-"));
			"*":	return follow("=",`ME,"*");
			"/":	return follow("=",`DE,"/");
			"%":	return follow("=",`MME,"%");
			";":	begin	
						eat_whitespace();
						case (1)
							infor :		begin r = $ungetc(c, file); return ";"; end
							c == "\n":  begin `LINENOPP; return "\n"; end 
							default :	begin r = $ungetc(c, file); return yylex(); end
						endcase
					end
			"\n":	begin `LINENOPP return "\n"; end
			default:	return c;
		endcase
	endfunction

	function void eat_whitespace ();
		while ((c=$fgetc(file)) == " " || c == "\t" || c == 13)
			;
	endfunction

	function int numsym(shortint first);
		int isbin = 0, isfloat = 0, ishex = 0, i = 0;
		string sel;
		Symbol s = new();
		string sbuf;

		sbuf = {sbuf, string'(c)};

		if(c == ".")
			isfloat = 1;

		if(isdigit(c) || isfloat) begin
			while(1) begin
				c = $fgetc(file);
				i++;
				if(c < 0)
					execerror("<eof> eating symbols", "");

				if(c == "\n")
					`LINENOPP
				sel = "01234567890.xb";
				if(ishex)
					sel = "01234567890abcdefABCDEF";
				else if(isbin)
					sel = "01";
				else if(isfloat)
					sel = "01234567890eE-+";

				if(index(sel, string'(c)) == 0) begin
					r = $ungetc(c, file);
					break;
				end
				if(c == ".")
					isfloat = 1;
				if(!isbin && c == "x")
					ishex = 1;
				if(!ishex && c == "b")
					isbin = 1;
				sbuf = {sbuf, string'(c)};
			end
/*
			if(isfloat) begin
				yylval.fval = atof(symbol);
				return Tfconst;
			end

			if(isbin)
				yylval.ival = strtoull(symbol+2, 0, 2);
			else
				yylval.ival = strtoll(symbol, 0, 0);
			return Tconst;
*/
		end

/*
		yylval.sym = s;
		return s->lexval;
*/
	endfunction

	function void skipcomment(); 
		// already eaten start comment delimiter
		while (1) begin
			c = $fgetc(file);
			case (c) 
				`EOF: return;
				"\n": `LINENOPP
				"\"": begin
					for (c=$fgetc(file); c != "\""; c=$fgetc(file)) 
						if (c == "\n" || c == `EOF)
							execerror("missing quote", "");
				end
				"*": begin // end of comment
					c = $fgetc(file);
					if (c == "/") // eat the end delimiter, comment finished, return
						return;
				end
				"/": begin 
					c = $fgetc(file);
					if (c == "*") // eat the start delimiter for the nested comment
						skipcomment(); // and go through skipcomment again
				end
			endcase
		end
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

	function Args formallist(Symbol formal, Args list);        /* add formal to list */
		Formal f = new();

		f.sym  = formal;
		list.push_front(f);

		return list;
	endfunction

	function void defnonly(string s);	/* warn if illegal definition */
		if (!indef)
			execerror(s, "used outside definition");
	endfunction

	task yyerror(string s);
		warning(s, "");
	endtask

	static task execerror(string s, string t);	/* recover from run-time error */
		warning(s, t);
		$finish;
	endtask

	static task warning(string s, string t);
		string sbuf;
		int byte_err = $ftell(file);

		$write("%s: %s", progname, s);
		if (t != "")
			$write(" %s", t);
		$write(" at byte %0d", byte_err);
		$write(" near line %0d\n", lineno);

		r = $fseek(file, lineoff, 0);

		while (c != "\n" && c != `EOF) begin
			c = $fgetc(file);		/* flush rest of input line */
			sbuf = {sbuf, string'(c)};
		end
		for(int i = 0; i < (byte_err - lineoff); i++) $write(" ");
		$display("v");
		$display(sbuf);	
		$finish;
	endtask


	task run_();
		int do_exec = 1;
		Process p = new();

		if ($test$plusargs("yydebug")) yydebug = 1;
		else yydebug = 0;
		if ($test$plusargs("yyparseonly")) do_exec = 0;

		init();
		indef = 0;
		infor = 0;
		Process::yydebug = yydebug;
		p.initcode();
		while (yyparse()) begin
			p.dump_prog();
			if (do_exec) p.execute(Process::progbase);
			indef = 0;
			infor = 0;
			p.initcode();
		end
		if (! do_exec) $display ("succesful syntax parse!!");
	endtask
endclass
