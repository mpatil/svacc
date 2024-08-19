CC      = gcc
CFLAGS  = -O -Wno-unused-result -Wno-implicit-function-declaration
LDFLAGS = -static
TAR     = tar
GZIP    = gzip
ZIP     = zip
VCSFLAGS = -full64 -debug_all -debug_pp +libext+.sv+ -CFLAGS -ggdb -notice \
           -Xcheck_p1800_2009=char -sverilog +vc+list
QBLDFLAGS = -optimize -64 -top hoc\
            +define+UVM +define+UVM_NO_DEPRECATED -timescale 1ns/1ps -permissive \
            -mfcu +nospecify +notimingchecks +acc=na \
            -suppress vopt-13177 -suppress vlog-2240 -suppress vlog-2875 -suppress vlog-2897 \
            -suppress vlog-2587  -suppress vlog-2250
QRUNFLAGS = -simulate -64 -permissive -permit_unmatched_virtual_intf -do "run -a;q" -top hoc

INC     = -I.

OBJ 	= closure.o \
	error.o \
	lalr.o \
	lr0.o \
	main.o \
	mkpar.o \
	output.o \
	reader.o \
	skeleton.o \
	symtab.o \
	verbose.o \
	warshall.o

qhoc8: qrun_hoc8 test/hoc8.expr
	qrun $(QRUNFLAGS) -l hoc8.log -outdir qrun_hoc8.out +input=test/hoc8.expr

hoc8: simv_hoc8 test/hoc8.expr
	simv_hoc8 -l hoc8.log +input=test/hoc8.expr

qhoc7: qrun_hoc7 test/hoc7.expr
	qrun $(QRUNFLAGS) -l hoc7.log -outdir qrun_hoc7.out +input=test/hoc7.expr

hoc7: simv_hoc7 test/hoc7.expr
	simv_hoc7 -l hoc7.log +input=test/hoc7.expr

qhoc6: qrun_hoc6 test/hoc6.expr
	qrun $(QRUNFLAGS) -l hoc6.log -outdir qrun_hoc6.out +input=test/hoc6.expr

hoc6: simv_hoc6 test/hoc6.expr
	simv_hoc6 -l hoc6.log +input=test/hoc6.expr

qhoc5: qrun_hoc5 test/hoc5.expr
	qrun $(QRUNFLAGS) -l hoc5.log -outdir qrun_hoc5.out +input=test/hoc5.expr

hoc5: simv_hoc5 test/hoc5.expr
	simv_hoc5 -l hoc5.log +input=test/hoc5.expr

qhoc4: qrun_hoc4 test/hoc4.expr
	qrun $(QRUNFLAGS) -l hoc4.log -outdir qrun_hoc4.out +input=test/hoc4.expr

hoc4: simv_hoc4 test/hoc4.expr
	simv_hoc4 -l hoc4.log +input=test/hoc4.expr

qhoc3: qrun_hoc3 test/hoc3.expr
	qrun $(QRUNFLAGS) -l hoc3.log -outdir qrun_hoc3.out +input=test/hoc3.expr

hoc3: simv_hoc3 test/hoc3.expr
	simv_hoc3 -l hoc3.log +input=test/hoc3.expr

qhoc2: qrun_hoc2 test/hoc2.expr
	qrun $(QRUNFLAGS) -l hoc2.log -outdir qrun_hoc2.out +input=test/hoc2.expr

hoc2: simv_hoc2 test/hoc2.expr
	simv_hoc2 -l hoc2.log +input=test/hoc2.expr

qhoc1.5: qrun_hoc15 test/hoc1.5.expr
	qrun $(QRUNFLAGS) -l hoc15.log -outdir qrun_hoc15.out +input=test/hoc1.5.expr

hoc1.5: simv_hoc15 test/hoc1.5.expr
	simv_hoc15 -l hoc15.log +input=test/hoc1.5.expr

qhoc1: qrun_hoc1 test/hoc1.expr
	qrun $(QRUNFLAGS) -l hoc1.log -outdir qrun_hoc1.out +input=test/hoc1.expr

hoc1: simv_hoc1 test/hoc1.expr
	simv_hoc1 -l hoc1.log +input=test/hoc1.expr

qrun_hoc8: Hoc8.sv test/hoc8/init.sv test/hoc8/code.sv test/hoc8/hoc.h test/hoc8/bio.h
	/apps/mentor/questa_sim-2023.1/questasim/linux_x86_64/qrun $(QBLDFLAGS) \
		-outdir qrun_hoc8.out +incdir+test/hoc8 test/hoc8/psystem.c Hoc8.sv

simv_hoc8: Hoc8.sv test/hoc8/init.sv test/hoc8/code.sv test/hoc8/hoc.h test/hoc8/bio.h
	vcs $(VCSFLAGS) +incdir+test/hoc8 -o simv_hoc8 test/hoc8/nu_net_bfm.c test/hoc8/psystem.c Hoc8.sv

qrun_hoc7: Hoc7.sv test/hoc7/init.sv test/hoc7/code.sv test/hoc7/hoc.h
	/apps/mentor/questa_sim-2023.1/questasim/linux_x86_64/qrun $(QBLDFLAGS) \
		-outdir qrun_hoc7.out +incdir+test/hoc7 Hoc7.sv

simv_hoc7: Hoc7.sv test/hoc7/init.sv test/hoc7/code.sv test/hoc7/hoc.h
	vcs $(VCSFLAGS) +incdir+test/hoc7 -o simv_hoc7 Hoc7.sv

qrun_hoc6: Hoc6.sv test/hoc6/init.sv test/hoc6/code.sv test/hoc6/hoc.h
	/apps/mentor/questa_sim-2023.1/questasim/linux_x86_64/qrun $(QBLDFLAGS) \
		-outdir qrun_hoc6.out +incdir+test/hoc6 Hoc6.sv

simv_hoc6: Hoc6.sv test/hoc6/init.sv test/hoc6/code.sv test/hoc6/hoc.h
	vcs $(VCSFLAGS) +incdir+test/hoc6 -o simv_hoc6 Hoc6.sv

qrun_hoc5: Hoc5.sv test/hoc5/init.sv test/hoc5/code.sv test/hoc5/hoc.h
	/apps/mentor/questa_sim-2023.1/questasim/linux_x86_64/qrun $(QBLDFLAGS) \
		-outdir qrun_hoc5.out +incdir+test/hoc5 Hoc5.sv

simv_hoc5: Hoc5.sv test/hoc5/init.sv test/hoc5/code.sv test/hoc5/hoc.h
	vcs $(VCSFLAGS) +incdir+test/hoc5 -o simv_hoc5 Hoc5.sv

qrun_hoc4: Hoc4.sv test/hoc4/init.sv test/hoc4/code.sv test/hoc4/hoc.h
	/apps/mentor/questa_sim-2023.1/questasim/linux_x86_64/qrun $(QBLDFLAGS) \
		-outdir qrun_hoc4.out +incdir+test/hoc4 Hoc4.sv

simv_hoc4: Hoc4.sv test/hoc4/init.sv test/hoc4/code.sv test/hoc4/hoc.h
	vcs $(VCSFLAGS) +incdir+test/hoc4 -o simv_hoc4 Hoc4.sv

qrun_hoc3: Hoc3.sv test/hoc3/init.sv test/hoc3/hoc.h
	/apps/mentor/questa_sim-2023.1/questasim/linux_x86_64/qrun $(QBLDFLAGS) \
		-outdir qrun_hoc3.out +incdir+test/hoc3 Hoc3.sv

simv_hoc3: Hoc3.sv test/hoc3/init.sv test/hoc3/hoc.h
	vcs $(VCSFLAGS) +incdir+test/hoc3 -o simv_hoc3 Hoc3.sv

qrun_hoc2: Hoc2.sv
	/apps/mentor/questa_sim-2023.1/questasim/linux_x86_64/qrun $(QBLDFLAGS) \
		-outdir qrun_hoc2.out Hoc2.sv

simv_hoc2: Hoc2.sv
	vcs $(VCSFLAGS) -o simv_hoc2  Hoc2.sv

qrun_hoc15: Hoc15.sv
	/apps/mentor/questa_sim-2023.1/questasim/linux_x86_64/qrun $(QBLDFLAGS) \
		-outdir qrun_hoc15.out Hoc15.sv

simv_hoc15: Hoc15.sv
	vcs $(VCSFLAGS) -o simv_hoc15  Hoc15.sv

qrun_hoc1: Hoc1.sv
	/apps/mentor/questa_sim-2023.1/questasim/linux_x86_64/qrun $(QBLDFLAGS) \
		-outdir qrun_hoc1.out Hoc1.sv

simv_hoc1: Hoc1.sv
	vcs $(VCSFLAGS) -o simv_hoc1  Hoc1.sv

Hoc8.sv: yacc test/hoc8/hoc.y
	./yacc -SVsemantic=svtype -v test/hoc8/hoc.y
	@mv Parser.sv Hoc8.sv

Hoc7.sv: yacc test/hoc7/hoc.y
	./yacc -SVsemantic=svtype -v test/hoc7/hoc.y
	@mv Parser.sv Hoc7.sv

Hoc6.sv: yacc test/hoc6/hoc.y
	./yacc -SVsemantic=svtype -d test/hoc6/hoc.y
	@mv Parser.sv Hoc6.sv
	@mv y.tab.h test/hoc6

Hoc5.sv: yacc test/hoc5/hoc.y
	./yacc -SVsemantic=svtype -d test/hoc5/hoc.y
	@mv Parser.sv Hoc5.sv
	@mv y.tab.h test/hoc5

Hoc4.sv: yacc test/hoc4/hoc.y
	./yacc -SVsemantic=svtype -d test/hoc4/hoc.y
	@mv Parser.sv Hoc4.sv
	@mv y.tab.h test/hoc4

Hoc3.sv: yacc test/hoc3/hoc.y
	./yacc -SVsemantic=svtype -d test/hoc3/hoc.y
	@mv Parser.sv Hoc3.sv
	@mv y.tab.h test/hoc3

Hoc2.sv: yacc test/hoc2.y
	./yacc -SVsemantic=svtype test/hoc2.y
	@mv Parser.sv Hoc2.sv

Hoc15.sv: yacc test/hoc1.5.y
	./yacc -SVsemantic=real test/hoc1.5.y
	@mv Parser.sv Hoc15.sv

Hoc1.sv: yacc test/hoc1.y
	./yacc -SVsemantic=real test/hoc1.y
	@mv Parser.sv Hoc1.sv

all: yacc

dist:
	( \
	cd .. ; \
	/bin/rm -rf $(VERS) ; \
	/bin/mkdir -p $(VERS) ; \
	/bin/mkdir -p dist ; \
        /bin/cp -r docs $(VERS) ; \
	/bin/mkdir -p $(VERS)/src ; \
        /bin/cp src/*.c $(VERS)/src ; \
        /bin/cp src/*.h $(VERS)/src ; \
        /bin/cp src/Makefile $(VERS)/src ; \
        /bin/cp src/Makefile.bcc $(VERS)/src ; \
        /bin/cp -f src/yacc $(VERS) ; \
        /bin/cp src/README $(VERS) ; \
	$(TAR) -cvf - $(VERS) | $(GZIP) > dist/$(VERS).tar.gz ;\
	$(ZIP) dist/$(VERS).zip $(VERS) \
	)

SRCS   = closure.c \
	error.c \
	lalr.c \
	lr0.c \
	main.c \
	mkpar.c \
	output.c \
	reader.c \
	skeleton.c \
	symtab.c \
	verbose.c \
	warshall.c

%.o : %.c
	$(CC) -c $(CFLAGS) $(INC) $< -o $@

yacc: $(OBJ)
	$(CC) -o yacc $(OBJ)
	@echo "done"

clean:
	/bin/rm -rf *.o  *.obj yacc y.tab.c Parser.sv Hoc*.sv *.log qrun* y.output
	/bin/rm -rf yacc simv* ucli.key csrc simv.daidir y.tab.h DVEfiles inter.vpd
	(cd .. ; /bin/rm -rf $(VERS) ; /bin/rm -rf dist )

### Dependencies
closure.o:  closure.c defs.h
error.o:    error.c defs.h
lalr.o:     lalr.c defs.h
lr0.o:      lr0.c defs.h
main.o:     main.c defs.h
mkpar.o:    mkpar.c defs.h
output.o:   output.c defs.h
reader.o:   reader.c defs.h
skeleton.o: skeleton.c defs.h
symtab.o:   symtab.c defs.h
verbose.o:  verbose.c defs.h
warshall.o: warshall.c defs.h

