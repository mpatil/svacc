// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
//-----------------------------------------------------------------------------------------------------
%{
`include "svc.h"
`define	EOF	-1
typedef class Parser;
integer r = 0;
integer file_din = 0, file = 0;

function real my_func (real Val1, real Val2, real Val3) ;
	return 1;
endfunction

program automatic svc;
	Parser p;
	initial begin : prog
		string filename, file_din_name;
		if ($value$plusargs("input=%s", filename)) 
			file = $fopen(filename, "r");
		if (file == 0) disable prog;
		if ($value$plusargs("data=%s", file_din_name)) 
			file_din = $fopen(file_din_name, "r");
		p = new();
		p.register_builtin_fn("my_func", 3);
		p.register_var("my_opt", 3);
		p.run_();
		$fclose(file);
	end
endprogram

class Parser;
	typedef class Process;
	static int	indef, infor;

%}

%union {
	Symbol	sym;		/* symbol table pointer */
	Inst	inst;		/* machine instruction */
	int		narg;		/* number of arguments */
	Args	formals;	/* list of formal parameters */
	int		mode;
}
%token	<sym>		NUMBER STRING VAR CONST FUNCTION BLTINFN BLTINTSK UNDEF PROCEDURE VEC DICT EV /* types */
%token	<sym>		PRINT WHILE IF ELSE EVENT						/* keywords */
%token	<sym>		RETURN FUNC PROC READ TRIGGER					/* keywords */
%token	<sym>		FOR CASE DEFAULT BREAK VECTOR DICTIONARY FORK	/* keywords */
%type	<formals>	formals
%type	<inst>		defn expr sexpr stmt asgn prlist stmtlist break
%type	<inst>		for case cases case_expr case_stmt case_def 
%type	<inst>		cond while if begin end vecvar fork forks fork_stmt 
%type	<sym>		procname 
%type	<narg>		arglist dictlist
%type	<mode>		optexpr
%right	'='
%nonassoc AE SE ME DE MME ANDE ORE XORE LSE RSE    /* += -= *= /= %= &= |= ^= <<= >>= */
%nonassoc IFX
%nonassoc ELSE
%left	OR				/* || */
%left	AND				/* && */
%left	'|'				/* | */
%left	'^'				/* ^ */
%left	'&'				/* & */
%nonassoc	'?' ':'			/* ?: */
%nonassoc	EQ NE			/* == != */
%nonassoc	'>' GE '<' LE	/* > >= < <= */
%nonassoc	LS RS			/* << >> */
%left	'+' '-'
%left	'*' '/' '%'
%nonassoc	EXP				/* exponentiation */
%nonassoc	UNARYMINUS NOT PP MM TRIGGER	/* - ! ++ -- */
%%
list:	/* nothing */
	| list stmt		{ `icode("STOP"); return 1; }
	| list error 	{ $finish; }
	;
asgn:	VAR '=' expr { $$=$3; `icode("assign"); `ocode($1); }
	| vecvar '=' expr { $$=$3; `icode("vecassign"); }
	| VAR AE expr	{ $$=$3; `icode2("vareq", "+=");  `ocode($1); }
	| VAR SE expr	{ $$=$3; `icode2("vareq", "-=");  `ocode($1); }
	| VAR ME expr	{ $$=$3; `icode2("vareq", "*=");  `ocode($1); }
	| VAR DE expr	{ $$=$3; `icode2("vareq", "/=");  `ocode($1); }
	| VAR MME expr	{ $$=$3; `icode("modeq");         `ocode($1); }
	| VAR ANDE expr	{ $$=$3; `icode2("vareq", "&=");  `ocode($1); }
	| VAR ORE expr	{ $$=$3; `icode2("vareq", "|=");  `ocode($1); }
	| VAR XORE expr	{ $$=$3; `icode2("vareq", "^=");  `ocode($1); }
	| VAR LSE expr	{ $$=$3; `icode2("vareq", "<<="); `ocode($1); }
	| VAR RSE expr	{ $$=$3; `icode2("vareq", ">>="); `ocode($1); }
	;
stmt:	asgn ';'	{ `icode("pop"); }
	| expr	';'   		{ $$ = $1; }
	| defn	   		{ $$ = $1; }
	| RETURN  ';'	{ defnonly("return"); `icode("procret"); }
	| RETURN expr ';'	{ defnonly("return"); $$ = $2; `icode("funcret"); }
	| PROCEDURE '(' begin arglist ')' ';'	{ $$ = $3; `icode("call"); `ocode($1); `ncode($4); }
	| BLTINTSK '(' begin arglist ')' ';'	{ $$ = $3;`icode2("bltin", "task"); `ocode($1);`ncode($4); }
	| PRINT prlist ';'	{ $$ = $2; }
	| BREAK break ';'	{ $$ = $2; }
	| '#' expr	';'	{ `icode("waitcode"); }
	| '@' EV ';'	{ `icode2("waitcode", "event"); `ocode($2); }
	| TRIGGER EV ';'{ `icode("triggercode"); `ocode($2); }
	| fork '{' end forks '}' { /* fork */
				`pcode($1.ptr + 1, $4); }	/* end */
	| case '(' cond ')' '{' cases case_def '}' end { /* case */
				`pcode($1.ptr + 1, $6);		/* first case entry */
				`pcode($1.ptr + 2, $7);		/* default case entry */
				`pcode($1.ptr + 3, $9); }	/* end */
	| while '(' cond ')' stmt end {			/* while */
				`pcode($1.ptr + 1, $5);		/* body of loop */
				`pcode($1.ptr + 2, $6); }	/* end, if cond fails */
	| for {infor = 1; } '(' asgn ';' cond ';' cond ')' {infor = 0; } stmt end {	/* for */
				`pcode($1.ptr + 1, $6);		/* condition */
				`pcode($1.ptr + 2, $8);		/* post loop */
				`pcode($1.ptr + 3, $11);	/* body of loop */
				`pcode($1.ptr + 4, $12); }	/* end, if cond fails */
	| if '(' cond ')' stmt end %prec IFX {	/* else-less if */ 
				`pcode($1.ptr + 1, $5);		/* thenpart */
				`pcode($1.ptr + 3, $6); }	/* end, if cond fails */
	| if '(' cond ')' stmt end ELSE stmt end {  /* if with else */
				`pcode($1.ptr + 1, $5);		/* thenpart */
				`pcode($1.ptr + 2, $8);		/* elsepart */
				`pcode($1.ptr + 3, $9); }	/* end, if cond fails */
	| VECTOR VAR '[' optexpr ']' ';' { $2.type_=`VEC; if ($4) `icode2("decvec", "d"); else yyerror("need array size"); `ocode($2);}
	| VECTOR VAR '[' optexpr ']' '=' '{' arglist '}' ';' { $2.type_=`VEC; if($4) `icode2("decvec", "dd"); else `icode2("decvec", "vd"); `ocode($2); `ncode($8); }
	| DICTIONARY  VAR ';' { $2.type_=`DICT; `icode("decdict"); `ocode($2); }
	| DICTIONARY  VAR '=' '{' dictlist '}' ';' { $2.type_=`DICT; `icode2("decdict", "vd"); `ocode($2); `ncode($5); }
	| EVENT  VAR ';' { $2.type_=`EV; `icode("decevent"); `ocode($2); }
	| '{' stmtlist '}'	{ $$ = $2; }
	;
optexpr: /*nothing */	{$$ = 0;}
	| expr				{$$ = 1;}
	;
cond:	expr	{ `icode("STOP"); }
	;
fork:	FORK	{ $$.ptr = `icode("forkcode"); `icode("STOP"); }
	;
forks:	fork_stmt 
	| forks fork_stmt		{ $$ = $2; }
	;
fork_stmt:	stmt	{ `icode("STOP"); } end { $$ = $3; `pcode($1.ptr - 1, $3); }
	;
case:	CASE { $$.ptr = `icode("casecode"); `icode("STOP"); `icode("STOP"); `icode("STOP"); }
	;
cases: case_expr case_stmt    		{ `pcode($1.ptr - 1, $2); `icode("STOP"); }
	| cases case_expr case_stmt 	{ `pcode($2.ptr - 1, $3); `icode("STOP"); }
	;
case_expr: expr { `icode("STOP"); }
	;
case_stmt: ':' stmt		{  `icode("STOP"); $$.ptr=`progp; }
	;
case_def: /* nothing */ { $$.ptr = `progp; `icode("STOP");}
	| { $$.ptr = `progp; } DEFAULT case_stmt	{ `icode("STOP"); }
	;
vecvar:	VAR '[' expr ']'	{ `icode("varpush"); `ocode($1); }
	| VEC '[' expr ']'		{ `icode("varpush"); `ocode($1); }
	| DICT  '[' expr ']'	{ `icode("varpush"); `ocode($1); }
	| expr '[' expr ']'		{ `icode2("varpush", "sub"); }
	;
while:	WHILE	{ $$.ptr = `icode("whilecode"); `icode("STOP"); `icode("STOP"); }
	;
for:	FOR	{ $$.ptr = `icode("forcode"); `icode("STOP"); `icode("STOP"); `icode("STOP"); `icode("STOP");}
	;
if:		IF	{ $$.ptr = `icode("ifcode"); `icode("STOP"); `icode("STOP"); `icode("STOP"); } %prec IFX
	;
begin:	/* nothing */	{ $$.ptr = `progp; }
	;
end:	/* nothing */	{ `icode("STOP"); $$.ptr = `progp; }
	;
break:	/* nothing */ { $$.ptr = `icode("break"); }
	;
stmtlist: /* nothing */		{ $$.ptr = `progp; }
	| stmtlist stmt 
	;
expr: CONST		{ $$.ptr = `icode("constpush"); `ocode($1); }
	| VEC		{ $$.ptr = `icode("constpush"); `ocode($1); }
	| DICT		{ $$.ptr = `icode("constpush"); `ocode($1); }
	| '&' VEC	{ $$.ptr = `icode2("constpush", "ref"); `ocode($2); }
	| '&' DICT	{ $$.ptr = `icode2("constpush", "ref"); `ocode($2); }
	| VEC '[' expr ':' expr ']'	{ `icode2("constpush","slice"); `ocode($1); }
	| FUNCTION	{ $$.ptr = `icode("constpush"); `ocode($1); }
	| VAR		{ $$.ptr = `icode("varpush");   `ocode($1); `icode("eval"); }
	| '&' VAR	{ $$.ptr = `icode2("varpush", "ref");   `ocode($2); `icode("eval"); }
	| vecvar	{ `icode2("eval", "vecvar"); }
	| VAR '(' begin arglist ')'	{ $$ = $3; `icode("call");`ocode($1);`ncode($4); }
	| FUNCTION '(' begin arglist ')'	{ $$ = $3; `icode("call");`ocode($1);`ncode($4); }
	| READ '(' VAR ')'	{ $$.ptr = `icode("varread"); `ocode($3); }
	| BLTINFN '(' begin arglist ')'	{ $$ = $3;`icode2("bltin","fn"); `ocode($1);`ncode($4); }
	| '(' expr ')'	{ $$ = $2; }
	| expr '+' expr	{ `icode2("binarithop", "+"); }
	| expr '-' expr	{ `icode2("binarithop", "-"); }
	| expr '*' expr	{ `icode2("binarithop", "*"); }
	| expr '/' expr	{ `icode2("binarithop", "/"); }
	| expr '%' expr	{ `icode("mod"); }
	| expr EXP expr	{ `icode2("binarithop", "**"); }
	| '-' expr		{ $$ = $2; `icode("negate"); } %prec UNARYMINUS 
	| expr LS expr	{ `icode2("binarithop", "<<"); }
	| expr RS expr	{ `icode2("binarithop", ">>"); }
	| expr '>' expr	{ `icode2("binrelop", ">"); }
	| expr GE expr	{ `icode2("binrelop", ">="); }
	| expr '<' expr	{ `icode2("binrelop", "<"); }
	| expr LE expr	{ `icode2("binrelop", "<="); }
	| expr EQ expr	{ `icode2("binrelop", "=="); }
	| expr NE expr	{ `icode2("binrelop", "!="); }
	| expr '&' expr	{ `icode2("binarithop", "&"); }
	| expr '|' expr	{ `icode2("binarithop", "|"); }
	| expr '^' expr	{ `icode2("binarithop", "^"); }
	| NOT expr		{ $$ = $2; `icode("not"); } %prec NOT
	| expr AND	{ $$.ptr = `icode2("sc", "&&"); } expr end { `icode2("binrelop", "&&"); `pcode($3.ptr, $5);} %prec AND
	| expr OR	{ $$.ptr = `icode2("sc", "||"); } expr end { `icode2("binrelop", "||"); `pcode($3.ptr, $5);} %prec OR
	| expr '?'	{ $$.ptr = `icode2("sc", "?"); }  expr { $$.ptr = `icode2("sc", ":"); } ':' { `pcode($3.ptr, $5); } expr begin { `pcode($5.ptr, $9); }
	| PP VAR		{ $$.ptr = `icode2("preop", "++"); `ocode($2); } %prec PP
	| MM VAR 		{ $$.ptr = `icode2("preop", "--"); `ocode($2); } %prec MM
	| VAR PP		{ $$.ptr = `icode2("postop", "++"); `ocode($1); }
	| VAR MM		{ $$.ptr = `icode2("postop", "--"); `ocode($1); }
	;
prlist:	expr			{ `icode("prexpr"); }
	| prlist ',' expr	{ `icode("prexpr"); }
	;
defn:	FUNC procname	{ $2.type_=`FUNCTION; indef++; `icode("fundef"); `ocode($2); `icode("STOP"); pre_define($2);}
	    '(' formals ')' begin stmt { `icode("procret"); define($7.ptr, $2, $5); indef--; } end {`pcode($8.ptr - 1, $10);}
	| PROC procname		{ $2.type_=`PROCEDURE; indef++; `icode("fundef"); `ocode($2); `icode("STOP"); pre_define($2);}
	    '(' formals ')' begin stmt { `icode("procret"); define($7.ptr, $2, $5); indef--; } end {`pcode($8.ptr - 1, $10);}
	;
formals:	/* nothing */	{ Args f; $$ = f; /*$$ = 0;*/ }
	| VAR					{ Args f; $$ = formallist($1, f); }
	| VAR ',' formals		{ $$ = formallist($1, $3); }
	;
procname: VAR
	| FUNCTION
	| PROCEDURE
	;
sexpr: expr
	| '{' arglist '}'		{ `icode2("decvec", "anon"); `ncode($2);}
	| '{' dictlist '}'		{ `icode2("decdict", "anon"); `ncode($2);}
	;
arglist:	/* nothing */	{ $$ = 0; }
	| sexpr					{ $$ = 1; }
	| arglist ',' sexpr		{ $$ = $1 + 1; }
	;
dictlist:	/* nothing */	{ $$ = 0; }
	| expr ':' sexpr		{ $$ = 1; }
	| dictlist ',' expr ':' sexpr	{ $$ = $1 + 1; }
	;

%%
	/* end of grammar */
	static string progname = "svc";
	static Symbol	tmpfn[$];		/* tmp tracking of function nesting */
	static int	lineoff[shortint];
	static int	lineno = 1, lineno_= 0;
	static int	tokenoff = 0, tokenoff_ = 0;

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
	function shortint yylex();		/* svc */
		string sel;

		eat_whitespace();

		if (c == `EOF) begin
			`TOKENOFF
			return 0;
		end

		if (c == "\\") begin /* line continuation */
			if ((c = $fgetc(file)) == "\n") begin
				`LINENOPP
				`TOKENOFF
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
							`TOKENOFF
							return yylex();
						end
					end
				"*": begin
						skipcomment();
						`TOKENOFF
						return yylex();
					end
				default: r = $ungetc(c_, file);
			endcase
		end

		if (c == "." || isdigit(c)) begin	/* number */
			shortint res = numsym();
			if (res == `NUMBER) return `CONST;
		end

		if (isalpha(c) ||  c == "_") begin 
			Symbol s;
			string sbuf;

			do begin
				sbuf = {sbuf, string'(c)};
				c = $fgetc(file);
			end while ((c != `EOF) && (isalnum(c) || c == "_"));
			r = $ungetc(c, file);

			for (int i = 0; i < Process::symlist.size(); i++) begin 
				if (Process::symlist[i].exists(sbuf)) begin
					s = Process::symlist[i][sbuf];
					break;
				end
			end
			if (s == null) begin
				s = new();
				s.name = sbuf;
				s.type_ = `UNDEF;
				Process::symlist[0][sbuf] = s;
			end
			yylval.sym = s;
			`TOKENOFF
			return s.type_ == `UNDEF ? `VAR : s.type_;
		end
		if (c == "\"") begin	/* quoted string */
			string sbuf;
			Symbol s = new();
			StringVal u = new();

			for (c=$fgetc(file); c != "\""; c=$fgetc(file)) begin
				if (c == "\n" || c == `EOF) begin
					`TOKENOFF
					`LINENOPP
					execerror("missing end quote", "");
				end
				sbuf = {sbuf, string'(backslash(c))};
			end

			s.type_ = `STRING;
			s.u = u;
			u.val = sbuf;

			yylval.sym = s;
			`TOKENOFF
			return `CONST;
		end

		sel = "^><=!|&+-*/%";
		if (index(sel, string'(c)) != -1) begin
			string sbuf;
			shortint opmap[string] = {
										"^":shortint'("^"), "^=":`XORE,  
										">":shortint'(">"), ">=":`GE,  ">>":`RS, ">>=":`RSE,  
										"<":shortint'("<"), "<=":`LE,  "<<":`LS, "<<=":`LSE,  
										"=":shortint'("="), "==":`EQ,
										"!":`NOT, "!=":`NE,
										"|":shortint'("|"), "||":`OR,  "|=":`ORE,
										"&":shortint'("&"), "&&":`AND, "&=":`ANDE,
										"+":shortint'("+"), "+=":`AE,  "++":`PP,
										"-":shortint'("-"), "-=":`SE,  "--":`MM, "->":`TRIGGER,
										"*":shortint'("*"), "*=":`ME,  "**":`EXP,
										"/":shortint'("/"), "/=":`DE,
										"%":shortint'("%"), "%=":`MME,
										default:-1
									};
			do begin
				sbuf = {sbuf, string'(c)};
				c = $fgetc(file);
			end while (index(sel, string'(c)) != -1);
			r = $ungetc(c, file);
			do begin
				if (opmap.exists(sbuf)) begin `TOKENOFF return opmap[sbuf]; end
				c = sbuf.getc(sbuf.len() - 1);
				r = $ungetc(c, file);
				sbuf = sbuf.substr(0, sbuf.len() - 2);
			end while (sbuf.len());
		end

		if (c == "\n")	
			`LINENOPP
		`TOKENOFF
		return c;
	endfunction

	function void eat_whitespace ();
		while ((c=$fgetc(file)) == " " || c == "\t" || c == "\n" || c == 13) begin
			if (c == "\n")	
				`LINENOPP
		end
	endfunction

	function int numsym();
		typedef enum {_undet = 0, _int, _bin, _float, _hex} Fmt;
		Fmt fmt;
		string sel[Fmt];
		Symbol s = new();
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
			RealVal u = new();
			case (fmt)
				_float:		u.val = sbuf.atoreal(); 
				_bin:		u.val = real'(sbuf.atobin());
				_hex:		u.val = real'(sbuf.atohex()); 
				default:	u.val = real'(sbuf.atoi()); 
			endcase
			s.u = u;
		end
		s.type_ = `NUMBER;
		yylval.sym = s;
		return `NUMBER;
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

	task pre_define(Symbol sp);
		FnDefn fd = new();
		Symlist sl;

		fd.parent = tmpfn[0];

		tmpfn.push_front(sp);
		Process::symlist.push_front(sl);

		sp.u = fd;
	endtask

	task define(shortint fnptr, Symbol sp, Args f);	/* put func/proc in symbol table */
		int n;
		FnDefn fd;

		`cast(fd, sp.u, sp.name, "not a function type");

		fd.code = fnptr;		/* start of code */
		Process::progbase = Process::progp + 1;	/* next code starts here */

		fd.formals = f;
		fd.nargs = f.size();

		fd.symlist = Process::symlist.pop_front();
		tmpfn.pop_front();
	endtask

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

		$write("\n%s: %s", progname, s);
		if (t != "") $write(" %s", t);
		$write(" at byte %0d near line %0d. \n", tokenoff_, lineno_);

		r = $fseek(file, lineoff[lineno_], 0);

		c = $fgetc(file);		
		while (c != "\n" && c != `EOF) begin
			sbuf = {sbuf, string'(c)};
			c = $fgetc(file);
		end
		for(int i = 0; i < (tokenoff_ - lineoff[lineno_]) - 1; i++) $write(" ");
		$display("v");
		$display(sbuf);
		$display();
		$finish;
	endtask

	task run_();
		int do_exec = 1;
		Process p = new();

		if ($test$plusargs("yydebug")) yydebug = 1;
		else yydebug = 0;
		if ($test$plusargs("yyparseonly")) do_exec = 0;

		init();
		Process::symlist.push_front(Process::globals);
		indef = 0;
		infor = 0;
		Process::yydebug = yydebug;
		p.initcode();
		while (yyparse()) begin
			if (do_exec) p.execute(Process::progbase);
			infor = 0;
			p.initcode();
		end
		if (! do_exec) $display ("successful syntax parse!!");
	endtask
endclass
