svio: simv 
	simv -l test.log

simv: svio.h svio.sv psystem.c
	vcs -full64 -debug_all -debug_pp +libext+.sv+ -CFLAGS -ggdb -notice \
               -sverilog +vc+list -o simv psystem.c svio.sv

clean:
	/bin/rm -rf *.log vc_hdrs.h 
	/bin/rm -rf simv* ucli.key csrc simv.daidir  DVEfiles inter.vpd 
