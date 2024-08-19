QBLDFLAGS = -optimize -64 -top svc \
            +define+UVM +define+UVM_NO_DEPRECATED -timescale 1ns/1ps -permissive \
            -mfcu +nospecify +notimingchecks +acc=na \
            -suppress vopt-13177 -suppress vlog-2240 -suppress vlog-2875 -suppress vlog-2897 \
            -suppress vlog-2587  -suppress vlog-2250
QRUNFLAGS = -simulate -64 -permissive -permit_unmatched_virtual_intf -do "run -a;q" -top svc

qsvc: qrun_svc test.expr
	qrun $(QRUNFLAGS) -l test.log -outdir qrun_svc.out +input=test.expr

svc: simv test.expr
	simv -l test.log +input=test.expr

qrun_svc: svc.sv
	/apps/mentor/questa_sim-2023.1/questasim/linux_x86_64/qrun $(QBLDFLAGS) -outdir qrun_svc.out svc.sv

simv: svc.sv
	vcs -full64 -debug_all -debug_pp +libext+.sv+ -CFLAGS -ggdb -notice \
                -Xcheck_p1800_2009=char -sverilog +vc+list -o simv svc.sv

svc.sv: yacc svc.y
	./yacc -SVsemantic=real svc.y
	@mv Parser.sv svc.sv

yacc:
	cp ../yacc .

clean:
	/bin/rm -rf *.log vc_hdrs.h svc.sv y.output
	/bin/rm -rf simv* ucli.key csrc simv.daidir  DVEfiles inter.vpd 
