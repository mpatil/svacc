// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
%{

`include "svc.h"

typedef DictVal DataList[$]; 
static DataList d;

`define	EOF	-1
typedef class Parser;
integer file = 0, r = 0;
string filename;
integer yydebug = 0;

program automatic svc;
	Parser p;
	initial begin : prog
		if ($value$plusargs("input=%s", filename)) 
			file = $fopen(filename, "r");
		if (file == 0) disable prog;
		p = new();
		$value$plusargs("yydebug=%0d", yydebug);
		p.yydebug = yydebug;
		p.yyparse(); 
		$display("\n------------------------\n");
		for (int i = 0; i < d.size(); i++) begin p.show_dict(d[i]); $write("\n"); end
		$display("\n------------------------\n");
		$fclose(file);
	end
endprogram

`define cast(lhs, rhs, err1, err2) if (!$cast(lhs, rhs)) execerror(err1, err2)
class Parser;
%}
%union {
	Val		val;	/* value */
	string	label;	
}
%token	<val>		NUMBER STRING
%token	<label>		LABEL
%type	<val>		data csvlist csvhash 
%right	':' ','
%start list
%%
list:
	| list '{' csvhash '}'	{ DictVal h;  `cast(h, $3, "hash::", "not a hash"); d.push_back(h); }
	| list error			{ $finish; }
	;
csvhash:	LABEL ':' data		{ DictVal d = new(); $$ = csvhash($1, $3, d); }
	| csvhash ',' LABEL ':' data  { DictVal d; `cast(d, $1, "hash::", "not a hash"); $$ = csvhash($3, $5, d); }
	;
csvlist: /* nothing */	{ VectorVal l = new(); $$ = l; }
	| data				{ VectorVal l = new(); $$ = csvlist($1, l); }
	| csvlist ',' data 	{ VectorVal l; `cast(l, $1, "list::", "not a list"); $$ = csvlist($3, l); }
	;
data:	NUMBER 
	| STRING
	| '{' csvlist '}' { $$ = $2; }
	| '{' csvhash '}' { $$ = $2; }
	;
%%
	/* end of grammar */
	string progname = "svc";
	int	lineno = 1;

	function VectorVal csvlist(Val val, VectorVal list);
		list.vecs.push_back(val);
		return list;
	endfunction

	function DictVal csvhash(string label, Val val, DictVal hash);
		hash.dict[label] = val;
		return hash;
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

	function bit islower(int c);
		return  (c >= "a" && c <= "z");
	endfunction

	static int c;	/* global for use by warning() */
	function shortint yylex();		/* svc */
		while ((c=$fgetc(file)) == " " || c == "\t")
			;

		if (c == `EOF)
			return 0;

		if (c == "." || isdigit(c)) begin /* number */
			return numsym();
		end

		if (isalpha(c) ||  c == "_") begin
			string sbuf;

			do begin
				sbuf = {sbuf, string'(c)};
				c = $fgetc(file);
			end while ((c != `EOF) && isalnum(c));
			r = $ungetc(c, file);

			yylval.label = sbuf;
			return `LABEL;
		end

		if (c == "\"") begin	/* quoted string */
			string sbuf;
			StringVal u = new();

			for (c=$fgetc(file); c != "\""; c=$fgetc(file)) begin
				if (c == "\n" || c == `EOF) begin
					execerror("missing end quote", "");
				end
				sbuf = {sbuf, string'(backslash(c))};
			end
			u.val = sbuf;

			yylval.val = u;
			return `STRING;
		end

		if (c == "\n") begin
			lineno++;
			return yylex();
		end
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
			RealVal u = new();
			case (fmt)
				_float:		u.val = sbuf.atoreal(); 
				_bin:		u.val = real'(sbuf.atobin());
				_hex:		u.val = real'(sbuf.atohex()); 
				default:	u.val = real'(sbuf.atoi()); 
			endcase
			yylval.val = u;
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

	task show_vec (VectorVal v) ;
		string k;
		$write("{");
		for (int k = 0; k < v.vecs.size(); k++) begin
			case (v.vecs[k].get_type())
				"real":		begin RealVal u;	$cast(u, v.vecs[k]); $write("%0d, ", int'(u.val));	end 
				"string":	begin StringVal u;	$cast(u, v.vecs[k]); $write("\"%s\", ", u.val);	end 
				"dict":		begin DictVal u;	$cast(u, v.vecs[k]); show_dict(u); $write(", "); end 
				"vector":	begin VectorVal u;	$cast(u, v.vecs[k]); show_vec(u); $write(", ");	end 
			endcase
		end
		$write("}");
	endtask
	
	task show_dict (DictVal v) ;
		string k;
		$write("{");
		if(v.dict.first(k))
		do
			case (v.dict[k].get_type())
				"real":		begin RealVal u;	$cast(u, v.dict[k]); $write("%s:%0d, ", k, int'(u.val));	end 
				"string":	begin StringVal u;	$cast(u, v.dict[k]); $write("%s:\"%s\", ", k, u.val);	end 
				"dict":		begin DictVal u;	$cast(u, v.dict[k]); $write("%s:", k); show_dict(u); $write(", "); end 
				"vector":	begin VectorVal u;	$cast(u, v.dict[k]); $write("%s:", k); show_vec(u); $write(", ");	end 
			endcase
		while ( v.dict.next(k) );
		$write("}");
	endtask
endclass
