// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
`ifndef _SVIO_H_
`define _SVIO_H_ 1

`define		SVIOSZ		2*16384
`define		SVIOUNGETSZ	4		/* space for ungetc */
`define		SVIOID		'h314159
`define		SVIOEOF		-1

`define		SVIOINACT	0		/* states */
`define		SVIORACT	1
`define		SVIOWACT	2
`define		SVIOACTEOF	3

`define		SVIOEND		4

`define		OREAD		0       /* open for read */
`define		OWRITE		1       /* write */

`define		TFILE		0       /* file io */
`define		TPIPE		1       /* pipe io */

import "DPI" task Popen(input string cmd, output int rdfd, output int wrfd);
import "DPI" close = task Pclose(input int fd);
import "DPI" fsync = task Pflush(input int fd);
import "DPI" function int Pread(output byte unsigned out[], input int fd, input int bbuf, output int sz);
import "DPI" function int Pwrite(input byte unsigned in[], input int fd, input int bbuf, input int sz);

class SVio;
	int					icnt = 0;	/* negative number of bytes at end of buffer */
	int					ocnt;		/* number of bytes at beginning of buffer */
	int					rdline = 0;	/* number of bytes after rdline */
	int					state;		/* state: r/w/eof/inactive */
	int		unsigned	fid;		/* file id */
	int					flag = 0;	
	longint unsigned	offset = 0;	/* buffer offset in file/pipe */
	int					bsize;		/* size of buffer */
	longint unsigned	bbuf;		/* index of beginning of buffer */
	longint unsigned	ebuf;		/* index of end of buffer */
	longint unsigned		gbuf;		/* index of beginning of good data in buf */
	byte unsigned		b[`SVIOUNGETSZ+`SVIOSZ]; /* buffer */
	shortint unsigned	ty = `TFILE; /* type : pipe/file */

	function new(int unsigned f = 0, int mode = `OREAD, shortint unsigned ty = `TFILE);
		SVinits(f, mode, `SVIOUNGETSZ +`SVIOSZ);
		flag = `SVIOID;
		this.ty = ty;
	endfunction

	function int SVinits(int unsigned f, int mode, int size);
	
		shortint p = 0;	
		p += `SVIOUNGETSZ;	/* for SVungets */
		size -= `SVIOUNGETSZ;
	
		case(mode)
			`OREAD: begin
					state = `SVIORACT;
					ocnt = 0;
				end
			`OWRITE: begin
					state = `SVIOWACT;
					ocnt = -size;
				end
			default: begin
					$write("SVopen: unknown mode %0d\n", mode);
					return `SVIOEOF;
				end
		endcase

		bbuf = p;
		ebuf = p + size;
		bsize = size;
		gbuf = ebuf;
		fid = f;
		return 0;
	endfunction
	
	function int SVinit(int unsigned f, int mode);
		return SVinits(f, mode, `SVIOUNGETSZ +`SVIOSZ);
	endfunction
	
	task close();
		case(ty)
			`TFILE:		$fclose(fid);
			`TPIPE:		Pclose(fid);
		endcase
	endtask

	function int read(longint unsigned bbuf_, int bsize_);
		case(ty)
			`TFILE:		read = $fread(b, fid, bbuf_, bsize_);
			`TPIPE:		read = Pread(b, fid, bbuf_, bsize_);
		endcase
	endfunction

	task write(byte unsigned s[], int unsigned start, int unsigned count);
		case(ty)
			`TFILE:		for (int i = start; i < start + count; i++) $fwrite(fid, "%c", s[i]);
			`TPIPE:		Pwrite(s, fid, start, count);
		endcase
	endtask

	task flush();
		case(ty)
			`TFILE:		$fflush(fid);
			`TPIPE:		Pflush(fid);
		endcase
	endtask

	function int seek(longint unsigned offset_, longint unsigned op_);
		case(ty)
			`TFILE:		seek = $fseek(fid, offset_, op_);
			`TPIPE:		$error("not supported");
		endcase
	endfunction

	task SVterm();
		SVflush();
		if(flag == `SVIOID) begin
			flag = 0;
			close();
		end
	endtask

	function shortint SVgetc();
		int i;
	
		while(1) begin
			i = icnt;
			if(i != 0) begin
				icnt = i + 1;
				return b[i + ebuf];
			end
			if(state != `SVIORACT) begin
				if(state == `SVIOACTEOF)
					state = `SVIORACT;
				return `SVIOEOF;
			end
			for (int j = 0 ; j < `SVIOUNGETSZ; j++)
				b[bbuf - `SVIOUNGETSZ + j] = b[ebuf - `SVIOUNGETSZ + j];

			i = read(bbuf, bsize);
			gbuf = bbuf;
			if(i <= 0) begin
				state = `SVIOACTEOF;
				if(i < 0)
					state = `SVIOINACT;
				return `SVIOEOF;
			end
			if(i < bsize) begin
				for (int j = 0 ; j < i + `SVIOUNGETSZ; j++)
					b[ebuf - i - `SVIOUNGETSZ + j] = b[bbuf - `SVIOUNGETSZ + j];
				gbuf = ebuf - i;
			end
			icnt = -i;
			offset += i;
		end
	endfunction
	
	function int SVungetc();
		if(state == `SVIOACTEOF)
			state = `SVIORACT;
		if(state != `SVIORACT)
			return `SVIOEOF;
		icnt--;
		return 1;
	endfunction

	function int SVflush();
		case (state)
			`SVIOWACT: begin
					int n = bsize + ocnt;
					if(n == 0)
						return 0;
					write(b, bbuf, n);
					flush();

					offset += n;
					ocnt = - bsize;
					return 0;
				end
			`SVIOACTEOF: state = `SVIORACT;
			`SVIORACT: begin
					icnt = 0;
					gbuf = ebuf;
					return 0;
				end
		endcase
		return `SVIOEOF;
	endfunction

	function int SVputc(byte c);
		int i;
	
		while(1) begin
			i = ocnt;
			if(i) begin
				b[ebuf + i] = c;
				ocnt = ++i;
				return 0;
			end
			if(SVflush() == `SVIOEOF)
				break;
		end
		return `SVIOEOF;
	endfunction

	function string SVrdline(byte delim = 10);
		string res;
		int ip = 0, ep = 0;
		int i, j, k;
	
		i = -icnt;
		if(i == 0) begin
			// eof or other error
			if(state != `SVIORACT) begin
				if(state == `SVIOACTEOF)
					state = `SVIORACT;
				rdline = 0;
				gbuf = ebuf;
				return "";
			end
		end
	
		ip = ebuf - i;
		for (k = 0; k < i; k++)
			if(b[k + ip] == delim) begin ep = k + ip; break; end
		if(ep) begin
			j = (ep - ip) + 1;
			rdline = j;
			icnt += j;
			for (k = 0; k < (ep - ip); k++) res = {res, string'(b[ip + k])};
			return res;
		end
	
		// replenish data
		if(i < bsize)
			for (k = 0; k < i; k++)
				b[bbuf + k] = b[ip + k];
		gbuf = bbuf;
	
		// keep fetching data into buffer looking for the delim
		ip = bbuf + i;

		while(i < bsize) begin
			j = read(ip, bsize - i);
			if(j <= 0) begin
				// eof and no delim
				for (k = 0; k < i; k++) 
					b[ebuf - i + k] = b[bbuf + k];
				rdline = i;
				icnt = -i;
				gbuf = ebuf - i;
				return "";
			end
			offset += j;
			i += j;
			for (k = 0; k < j; k++)
				if(b[ip + k] == delim) begin ep = ip + k; break; end
			if(ep) begin
				// found delim
				ip = ebuf - i;
				if(i < bsize) begin
					for (k = 0; k < i; k++)
						b[ip + k] = b[bbuf + k];
					gbuf = ip;
				end
				j = (ep - bbuf) + 1;
				rdline = j;
				icnt = j - i;
				for (k = 0; k < ep - bbuf; k++) res = {res, string'(b[ip + k])};
				return res;
			end
			ip += j;
		end
	
		// no delim found
		rdline = bsize;
		icnt = -bsize;
		gbuf = bbuf;
		return "";
	endfunction
	
	function int SVlinelen();
		return rdline;
	endfunction

	function longint SVoffset();
		longint n;
	
		case(state)
			`SVIOACTEOF, `SVIORACT: n = offset + icnt;
			`SVIOWACT: n = offset + (bsize + ocnt);
			default: begin
					$write("SVoffset: unknown state %d\n", state);
					n = `SVIOEOF;
				end
		endcase
		return n;
	endfunction

	function longint SVseek(longint offset, int base);
		longint n, d;
		int bufsz;
	
		case(state)
			`SVIOACTEOF: begin
					state = `SVIORACT;
					icnt = 0;
					gbuf = ebuf;
				end	
			`SVIORACT: begin
					n = offset;
					if(base == 1) begin
						n += SVoffset();
						base = 0;
					end
					
					// seek inside buffer
					if(base == 0) begin
						d = n - SVoffset();
						bufsz = ebuf - gbuf;
						if(-bufsz <= d && d <= bufsz) begin
							icnt += d;
							if(d >= 0) begin
								if(icnt <= 0)
									return n;
							end else begin
								if(ebuf - gbuf >= -icnt)
									return n;
							end
						end
					end
					
					// else reset the buffer
					n = seek(n, base);
					icnt = 0;
					gbuf = ebuf;
				end
			`SVIOWACT: begin
					SVflush();
					n = seek(offset, base);
				end
			default: begin
					$write("SVseek: unknown state %0d\n", state);
					return `SVIOEOF;
				end
		endcase
		offset = n;
		return n;
	endfunction

	function longint SVread(longint unsigned count, ref byte unsigned ap[]);
		longint unsigned c = count, i = 0;
		int n, ic = icnt, k = 0;
	
		while(c > 0) begin
			n = -ic;
			if(n > c)
				n = c;
			if(n == 0) begin
				if(state != `SVIORACT) break;
				i = read(bbuf, count);
				if(i <= 0) begin
					state = `SVIOACTEOF;
					if(i < 0)
						state = `SVIOINACT;
					break;
				end
				gbuf = bbuf;
				offset += i;
				if(i < bsize) begin
					for (int j = 0 ; j < i; j++)
						b[ebuf - i + j] = b[bbuf + j];
					gbuf = ebuf - i;
				end
				ic = -i;
				continue;
			end
			for (int j = 0 ; j < n; j++)
				ap[k++] = b[ebuf + ic + j];
			c -= n;
			ic += n;
		end
		icnt = ic;
		return count - c;
	endfunction

	function longint SVwrite(longint unsigned count, input byte unsigned ap[]);
		longint unsigned c = count;
		longint unsigned ap_idx = 0;
		int i, n = 0, oc = ocnt;
	
		while(c > 0) begin
			n = -oc;
			if(n > c)
				n = c;
			if(n == 0) begin
				if(state != `SVIOWACT)
					return `SVIOEOF;

				write(b, bbuf, bbuf + bsize);
				flush();

				offset += i;
				oc = -bsize;
				continue;
			end
			for (int j = 0 ; j < n; j++)
				b[ebuf + oc +  j] = ap[ap_idx + j];
			oc += n;
			c -= n;
			ap_idx += n;
		end
		ocnt = oc;
		return count - c;
	endfunction

	function string SVrdstr(int delim = 10, int nulldelim = 0);
		string p, q;
		int n, linelen, i;
		byte unsigned nq[];
	
		n = 0;
		while(1) begin
			p = SVrdline(delim);
			linelen = SVlinelen();
			if(n == 0 && linelen == 0)
				return "";
			if(p != "") begin
				for (i = 0; i < linelen; i++)
					q = {q, p[i]};
				n += linelen;
				if(nulldelim)
					q[n-1] = "\0";
				break;
			end
			if(linelen == 0)
				break;
			SVread(linelen, nq);
			for (i = 0; i < linelen; i++)
				q = {q, nq[i]};
			n += linelen;
		end
		q[n] = "\0";
		return q;
	endfunction
endclass

task svcat(SVio bin, SVio bout, string name);
	int unsigned n;
	byte unsigned buf_[];

	while((n = bin.SVread(256, buf_)) > 0) begin
		if(bout.SVwrite(n, buf_) < 0)
			$write("svcat: writing during %s:\n", name);
		bout.SVflush();
	end
	if(n < 0)
		$write("svcat: reading %s: \n", name);	
endtask

function SVio SVopen(string name, int mode);
	int unsigned f;

	case(mode)
		`OREAD: begin
				f = $fopen(name, "rb");
				if(f < 0)
					return null;
			end
		`OWRITE: begin
				f = $fopen(name, "wb");
				if(f < 0)
					return null;
			end
		default: begin
				$write("SVopen: unknown mode %0d\n", mode);
				return null;
			end
	endcase
	SVopen = new(f, mode);
	if(SVopen == null)
		$fclose(f);
endfunction

`endif
