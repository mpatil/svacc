simv: bio.h bio_test.sv psystem.c
	vcs -full64 -debug_all -debug_pp +libext+.sv+ -CFLAGS -ggdb -notice \
                -R -sverilog +vc+list -o simv psystem.c bio_test.sv

clean:
	/bin/rm -rf *.log vc_hdrs.h 
	/bin/rm -rf simv* ucli.key csrc simv.daidir  DVEfiles inter.vpd 
