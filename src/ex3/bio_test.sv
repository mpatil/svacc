// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
`include "bio.h"

program automatic hoc;
	Biobuf bin;
	Biobuf bout;
	byte unsigned pkt[] = {	'hd4, 'hc3, 'hb2, 'ha1, 'h02, 'h00, 'h04, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 'h00, 
							'h00, 'h90, 'h01, 'h00, 'h0c, 'h00, 'h00, 'h00, 'hc1, 'hb4, 'hfa, 'h56, 'h00, 'h00, 'h00, 'h00, 
							'h34, 'h00, 'h00, 'h00, 'h34, 'h00, 'h00, 'h00, 'h45, 'h08, 'h00, 'h34, 'h65, 'hd1, 'h40, 'h00, 
							'h40, 'h06, 'h51, 'h9e, 'hc0, 'ha8, 'h00, 'hfe, 'hc0, 'ha8, 'h00, 'hfe, 'hdb, 'h62, 'h0c, 'hea, 
							'hcc, 'hd8, 'hbc, 'ha7, 'hcd, 'h34, 'h98, 'h95, 'h80, 'h10, 'h02, 'h12, 'ha5, 'he2, 'h00, 'h00, 
							'h01, 'h01, 'h08, 'h0a, 'h00, 'hf1, 'h39, 'h01, 'h00, 'hf1, 'h39, 'h01 };

	initial begin : prog
		int unsigned n;
		string t;
		byte unsigned s[];

		int stdout, stdin; 

		Popen("tcpdump -l -X -A -vvv -r -", stdout, stdin);
		bout = new(stdout, `OREAD, _process);
		bin = new(stdin, `OWRITE, _process);

		bin.Bwrite(pkt.size(), pkt);
		bin.Bterm();

		s = new [100];
		while((n = bout.Bread(100, s)) > 0)
			for (int k = 0; k < n; k++) t = {t, string'(s[k])};

		$write ("%s\n", t);
	end
endprogram
