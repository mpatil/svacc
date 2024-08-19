CC      = gcc
CFLAGS  = -O -Wno-unused-result -Wno-implicit-function-declaration
LDFLAGS = -static 
TAR     = tar
GZIP    = gzip
ZIP     = zip

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

hoc8: simv_hoc8 test/hoc8.expr 
	simv_hoc8 -l hoc8.log +input=test/hoc8.expr

hoc7: simv_hoc7 test/hoc7.expr 
	simv_hoc7 -l hoc7.log +input=test/hoc7.expr

hoc6: simv_hoc6 test/hoc6.expr 
	simv_hoc6 -l hoc6.log +input=test/hoc6.expr

hoc5: simv_hoc5 test/hoc5.expr 
	simv_hoc5 -l hoc5.log +input=test/hoc5.expr

hoc4: simv_hoc4 test/hoc4.expr 
	simv_hoc4 -l hoc4.log +input=test/hoc4.expr 

hoc3: simv_hoc3 test/hoc3.expr 
	simv_hoc3 -l hoc3.log +input=test/hoc3.expr

hoc2: simv_hoc2 test/hoc2.expr 
	simv_hoc2 -l hoc2.log +input=test/hoc2.expr 

hoc1.5: simv_hoc15 test/hoc1.5.expr 
	simv_hoc15 -l hoc15.log +input=test/hoc1.5.expr 

hoc1: simv_hoc1 test/hoc1.expr 
	simv_hoc1 -l hoc1.log +input=test/hoc1.expr 

simv_hoc8: Hoc8.sv test/hoc8/init.sv test/hoc8/code.sv test/hoc8/hoc.h test/hoc8/bio.h
	vcs -full64 -debug_all -debug_pp +libext+.sv+ -CFLAGS -ggdb -notice \
                -Xcheck_p1800_2009=char -sverilog +vc+list +incdir+test/hoc8 -o simv_hoc8 test/hoc8/nu_net_bfm.c test/hoc8/psystem.c Hoc8.sv

simv_hoc7: Hoc7.sv test/hoc7/init.sv test/hoc7/code.sv test/hoc7/hoc.h
	vcs -full64 -debug_all -debug_pp +libext+.sv+ -CFLAGS -ggdb -notice \
                -Xcheck_p1800_2009=char -sverilog +vc+list +incdir+test/hoc7 -o simv_hoc7 Hoc7.sv

simv_hoc6: Hoc6.sv test/hoc6/init.sv test/hoc6/code.sv test/hoc6/hoc.h
	vcs -full64 -debug_all -debug_pp +libext+.sv+ -CFLAGS -ggdb -notice \
                -Xcheck_p1800_2009=char -sverilog +vc+list +incdir+test/hoc6 -o simv_hoc6 Hoc6.sv

simv_hoc5: Hoc5.sv test/hoc5/init.sv test/hoc5/code.sv test/hoc5/hoc.h
	vcs -full64 -debug_all -debug_pp +libext+.sv+ -CFLAGS -ggdb -notice \
                -Xcheck_p1800_2009=char -sverilog +vc+list +incdir+test/hoc5 -o simv_hoc5 Hoc5.sv

simv_hoc4: Hoc4.sv test/hoc4/init.sv test/hoc4/code.sv test/hoc4/hoc.h 
	vcs -full64 -debug_all -debug_pp +libext+.sv+ -CFLAGS -ggdb -notice \
                -Xcheck_p1800_2009=char -sverilog +vc+list +incdir+test/hoc4 -o simv_hoc4 Hoc4.sv

simv_hoc3: Hoc3.sv test/hoc3/init.sv test/hoc3/hoc.h  
	vcs -full64 -debug_all -debug_pp +libext+.sv+ -CFLAGS -ggdb -notice \
                -Xcheck_p1800_2009=char -sverilog +vc+list +incdir+test/hoc3 -o simv_hoc3 Hoc3.sv

simv_hoc2: Hoc2.sv
	vcs -Xcheck_p1800_2009=char -full64 -debug_all -sverilog -o simv_hoc2  Hoc2.sv 

simv_hoc15: Hoc15.sv
	vcs -Xcheck_p1800_2009=char -full64 -debug_all -sverilog -o simv_hoc15  Hoc15.sv 

simv_hoc1: Hoc1.sv
	vcs -Xcheck_p1800_2009=char -full64 -debug_all -sverilog -o simv_hoc1  Hoc1.sv 

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
	/bin/rm -rf *.o  *.obj yacc y.tab.c Parser.sv Hoc*.sv *.log
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

