// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
%{
`define	EOF	-1


typedef class Parser;
integer file = 0, r = 0;
string filename;
integer yydebug = 0;

program automatic hoc;
	Parser p;
	initial begin : prog
        if ($value$plusargs("input=%s", filename)) 
			file = $fopen(filename, "r");
        if (file == 0) disable prog;
		p = new();
        $value$plusargs("yydebug=%0d", yydebug);
		p.yydebug = yydebug;
		p.yyparse();
        $fclose(file);
	end
endprogram

class Parser;
real mem[26];	/* memory for variables 'a'..'z' */

%}

%union {		/* stack type */
	real val;	/* actual value */
	int	index;	/* index into mem[] */
}

%token	<val>   NUMBER
%token	<index>	VAR
%type	<val>	expr
%right	'='
%left	'+' '-'	  /* left associative, same precedence */
%left	'*' '/'	  /* left assoc., higher precedence */
%left   UNARYMINUS
%%
list:	  /* nothing */
	| list '\n'
	| list expr '\n'    { $display("\t%0f\n", $2); }
	;
expr:	  NUMBER
	| VAR		    { $$ = mem[$1]; }
	| VAR '=' expr	{ $$ = $3; mem[$1] = $3;}	
	| expr '+' expr	{ $$ = $1 + $3; $display("\t%0f = %0f + %0f\n", $$, $1, $3);}
	| expr '-' expr	{ $$ = $1 - $3; $display("\t%0f = %0f - %0f\n", $$, $1, $3);}
	| expr '*' expr	{ $$ = $1 * $3; $display("\t%0f = %0f * %0f\n", $$, $1, $3);}
	| expr '/' expr	{ if ($3 == 0.0) 
                          execerror("division by zero", ""); 
                      $$ = $1 / $3; $display("\t%0f = %0f / %0f\n", $$, $1, $3);}
	| '(' expr ')'	{ $$ = $2;           $display("\t%0f = %0f\n", $$, $2);}
	| '-' expr  %prec UNARYMINUS { $$ = -$2; $display("\t%0f = -%0f\n", $$, $2);}
	;
%%
	/* end of grammar */

	string progname = "hoc.y";	/* for error messages */
	int	lineno = 1;

	function bit isdigit(int c);
		if (c >= "0" && c <= "9") return 1;
		return 0;
	endfunction

	function bit islower(int c);
		if (c >= "a" && c <= "z") return 1;
		return 0;
	endfunction

	function int yylex();		/* hoc2 */
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
	    if (islower(c)) begin
		    yylval.index = c - "a";	/* ASCII only */
		    return `VAR;
	    end
		if (c == "\n")
			lineno++;
		return c;
	endfunction

	task yyerror(string s);	/* called for yacc syntax error */
		warning(s, "");
	endtask

	task execerror(string s, string t);	/* recover from run-time error */
		warning(s, t);
		$finish;
	endtask	

	task warning(string s, string t);	/* print warning message */
		$display("%s: %s", progname, s);
		if (t != "")
			$display(" %s", t);
		$display(" near line %d\n", lineno);
	endtask

endclass
