// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

typedef byte unsigned Pkt[$];
static Pkt d[$];

`include "svio.h"

program automatic svio;
    SVio bout;

    initial begin : prog
        Pkt p;
        string line;

`ifdef FILEBASED
        bout = SVopen("pkt.hex", `OREAD);
`else
        int stdout, stdin;

        Popen("randpkt -t ip -b 256 -c 4 - | tcpdump -X -r -", stdout, stdin);
        bout = new(stdout, `OREAD, `TPIPE);
`endif

/* trying to decode pkt descriptons like..
22:30:49.000000 IP (tos 0x8, ttl  64, id 26065, offset 0, flags [DF], proto: TCP (6), length: 52) 192.168.0.254.56162 > 192.168.0.254.mysql: ., cksum 0xa5e2 (correct), 3436756135:3436756135(0) ack 3442776213 win 530 <nop,nop,timestamp 15808769 15808769>
	0x0000:  4508 0034 65d1 4000 4006 519e c0a8 00fe  E..4e.@.@.Q.....
	0x0010:  c0a8 00fe db62 0cea ccd8 bca7 cd34 9895  .....b.......4..
	0x0020:  8010 0212 a5e2 0000 0101 080a 00f1 3901  ..............9.
	0x0030:  00f1 3901                                ..9.
*/

`define DECODE(i, j)  begin string t = r.substr(i,j); p.push_back(t.atohex()); end

        for(int k = 0 ; k < 1000; k++) begin
            do begin
                line = bout.SVrdline();
                case (1)
                    line.match(".*IP"): begin if (p.size()) d.push_back(p); p = {}; continue; end
                    line.match("\t0x....: "): begin 
                        string s = line.postmatch();
                        while (1) begin
                            case (1)
                                s.match("(^ [a-fA-F0-9]{4})"): begin
                                    string r = s.thismatch();
                                    `DECODE(1, 2)   
                                    `DECODE(3, 4)   
                                end
                                s.match("(^ [a-fA-F0-9]{2})"): begin
                                    string r = s.thismatch();
                                    `DECODE(1, 2)   
                                end
                                default: break;
                            endcase
                            s = s.postmatch();
                        end
                        break;
                    end
                    default: break;
                endcase
            end while (1);
        end
        bout.SVterm();
        d.push_back(p);
        for (int k = 0; k < d.size(); k++) $write (d[k], "\n");

    end // initial

endprogram

