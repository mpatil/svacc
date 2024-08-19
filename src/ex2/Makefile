svc: simv test.expr
	simv -l test.log +input=test.expr

simv: svc.sv
	vcs -full64 -debug_all -debug_pp +libext+.sv+ -CFLAGS -ggdb -notice \
                -Xcheck_p1800_2009=char -sverilog +vc+list -o simv svc.sv

svc.sv: yacc svc.y 
	./yacc -SVsemantic=svtype svc.y
	@mv Parser.sv svc.sv

clean:
	/bin/rm -rf *.log vc_hdrs.h svc.sv y.output
	/bin/rm -rf simv* ucli.key csrc simv.daidir  DVEfiles inter.vpd 
