#    SPDX-FileCopyrightText: 2021,2024 Monaco F. J. <monaco@usp.br>. <monaco@usp.br>
#    SPDX-FileCopyrightText: 2024 ms-erik <erikmelges@usp.br>
#   
#    SPDX-License-Identifier: GPL-3.0-or-later
#
#  This file is a derivative work from SYSeg (https://gitlab.com/monaco/syseg)
#  and contains modifications carried out by the following author(s):
#  ms-erik <erikmelges@usp.br>

##
## Relevent files for this exercise.
##

all: hw.bin

hw.bin : hw.S hwasm
	./hwasm hw.S hw.bin

hwasm : hwasm.c
	gcc -Wall --ansi hwasm.c -o hwasm

hw2.bin: hw2.o
	ld -melf_i386 --oformat=binary -Ttext=0x7c00 hw2.o -o h2.bin

hw2.o: hw.S
	as --32 hw.S -o hw.o


.PHONY: clean

clean:
	rm -rf *.bin *.o
	rm -f *~ 

# Create stand-alone distribution

EXPORT_FILES = Makefile README


## Bintools: convenience rules for inspecting binary files
##
## SYSeg's Bintools is a collection of Makefile rules for invoking
## binary-inspection utility programs. It contains handy shortcuts for
## disassembling objects, comparing files, creating bootable images, invoking
## platform emulators and other facilities. Some shortcuts are ad hoc rules
## crafted under a poetic license and may depart from conventional Make usage.

##
## Configuration
##


# Inform your preferred graphical diff tool e.g meld, kdiff3 etc.

DIFF_TOOL=meld


##
## You probably don't need to change beyond this line
##

# Disassemble

# ALT = intel | att  (default: att)

ifndef ASM
ifeq (,$(findstring intel, $(MAKECMDGOALS)))
ASM_SYNTAX = att
else
ASM_SYNTAX = intel
endif
else
ASM_SYNTAX= $(ASM)
endif

# BIT = 16 | 32  (default: 32)

ifndef BIT
ifeq (,$(findstring 16, $(MAKECMDGOALS)))
ASM_MACHINE = i386
else
ASM_MACHINE = i8086
endif
else

ifeq ($(BIT),16)
ASM_MACHINE = i8086
else
ASM_MACHINE = i386
endif

endif


intel att 16 32: 
	@echo > /dev/null

##
## Options
##

opts = $(filter .optnop, $(MAKECMDGOALS))
symbol = $(filter ..%, $(MAKECMDGOALS))

$(opts) $(symbol):
	@echo > /dev/null

objdump_nop = "cat"
objdump_disassemble = "-d"

#
# Disassemble options
#

ifneq (,$(filter d diss d* diss*, $(MAKECMDGOALS)))


ifneq (,$(findstring .optnop, $(opts)))
objdump_nop = "sed 's/:\(\t.*\t\)/:    /g'"
endif

ifneq (,$(symbol))
objdump_disassemble = "--disassemble=$(symbol:..%=%)"
endif

endif


#
# Disassemble
#

diss d diss* d* : baz=$(bar)

diss d diss* d*: $(IMG) 
	@objdump -f $< > /dev/null 2>&1; \
	if test $$? -eq 1   ; then \
	  objdump -M $(ASM_SYNTAX) -b binary -m $(ASM_MACHINE) -D $< | "$(objdump_nop)"; \
	else \
	  if test $@ = "diss" || test $@ = "d" ; then\
	   objdump -M $(ASM_SYNTAX) -m $(ASM_MACHINE) $(objdump_disassemble) $<  | "$(objdump_nop)" ;\
	  else\
	    objdump -M $(ASM_SYNTAX) -m $(ASM_MACHINE) -D $< | "$(objdump_nop)" ; \
	 fi;\
	fi

%/diss %/d %/diss* %/d*: %
	make $(@F) IMG=$< $(filter 16 32 intel att $(opts) $(symbol), $(MAKECMDGOALS)) 

%/i16 %/16i : %
	make --quiet $</diss intel 16 $(opts) $(symbol)
%/i32 %/32i %/i: %
	make --quiet $</diss intel 32 $(opts) $(symbol)
%/a16 %/16a %/16 : %
	make --quiet $</diss att 16 $(opts) $(symbol)
%/a32 %/32a %/32 %/a: %
	make --quiet $</diss att 32 $(opts) $(symbol)

%/i16* %/16i* : %
	make --quiet $</diss* intel 16 $(opts) $(symbol)
%/i32* %/32i* %/i*: %
	make --quiet $</diss* intel 32 $(opts) $(symbol)
%/a16* %/16a* %/16* : %
	make --quiet $</diss* att 16 $(opts) $(symbol)
%/a32* %/32a* %/32* %/a*: %
	make --quiet $</diss* att 32 $(opts) $(symbol)

##
## Run on the emulator
##

# 
#
# %/run : %
# 	@i=$< &&\
# 	if test $${i##*.} = "img"; then\
# 	    make run-fd IMG=$<;\
# 	 else\
# 	   if test $${i##*.} = "bin"; then\
# 	     make run-bin IMG=$<;\
# 	    fi;\
# 	fi
#
# %/bin : %
# 	make run-bin IMG=$<
#
# %/fd : %
# 	make run-fd IMG=$<

%/run : %
	make run IMG=$<

run: $(IMG)
	qemu-system-i386 -drive format=raw,file=$< -net none

# These are deprecate; use %/run, instead.

run-bin: $(IMG)
	qemu-system-i386 -drive format=raw,file=$< -net none
	@echo "Shortcut run-bin is deprecated: use 'make run' instead."

run-iso: $(IMG)
	qemu-system-i386 -drive format=raw,file=$< -net none
	@echo "Shortcut run-iso is deprecated: use 'make run' instead."

run-fd : $(IMG)
	qemu-system-i386 -drive format=raw,file=$< -net none
	@echo "Shortcut run-fd is deprecated: use 'make run' instead."



# Dump contents in hexadecimal

hex raw dump: $(IMG)
	hexdump -C $<


%/hex %raw %/dump : %
	make --quiet dump IMG=$< 


# Diff-compare


MISSING_DIFF_TOOL="Can't find $(DIFF_TOOL); please edit syseg/tools/bintools.m4"

# Compare objects

objdiff bindiff : $(wordlist 2, 4, $(MAKECMDGOALS))
	if  test -z $$(which $(DIFF_TOOL)); then echo $(MISSING_DIFF_TOOL); exit 1; fi
	if test $(words $^) -lt 4 ; then\
	  bash -c "$(DIFF_TOOL) <(make $(wordlist 1,1,$^)/diss $(ASM) $(BIT)) <(make $(wordlist 2,2,$^)/diss $(ASM) $(BIT))";\
	else\
	  bash -c "$(DIFF_TOOL) <(make $(wordlist 1,1,$^)/diss $(ASM) $(BIT)) <(make $(wordlist 2,2,$^)/diss $(ASM) $(BIT)) <(make $(wordlist 3,3,$^)/diss $(ASM) $(BIT))";\
	fi

# Compare sources

srcdiff : $(wordlist 2, 4, $(MAKECMDGOALS))
	if  test -z $$(which $(DIFF_TOOL)); then echo $(MISSING_DIFF_TOOL); exit 1; fi
	if test $(words $^) -lt 3 ; then\
	  bash -c "$(DIFF_TOOL) $(wordlist 1,1,$^) $(wordlist 2,2,$^)";\
	else\
	  bash -c "$(DIFF_TOOL) $(wordlist 1,1,$^) $(wordlist 2,2,$^) $(wordlist 3,3,$^)";\
	fi

# Compare hex

hexdiff : $(wordlist 2, 4, $(MAKECMDGOALS))
	if  test -z $$(which $(DIFF_TOOL)); then echo $(MISSING_DIFF_TOOL); exit 1; fi
	if test $(words $^) -lt 4 ; then\
	  bash -c "$(DIFF_TOOL) <(make $(wordlist 1,1,$^)/hex $(ASM) $(BIT)) <(make $(wordlist 2,2,$^)/hex $(ASM) $(BIT))";\
	else\
	  bash -c "$(DIFF_TOOL) <(make $(wordlist 1,1,$^)/hex $(ASM) $(BIT)) <(make $(wordlist 2,2,$^)/hex $(ASM) $(BIT)) <(make $(wordlist 3,3,$^)/hex $(ASM) $(BIT))";\
	fi


# Compare objects and sources

diff : $(word 2, $(MAKECMDGOALS))
	@echo $(wordlist 2, 4, $(MAKECMDGOALS))
	@EXT=$(suffix $<);\
	case $$EXT in \
	.bin | .o)\
		make --quiet objdiff $(wordlist 2, 4, $(MAKECMDGOALS))\
		;;\
	.asm | .S | .s | .i | .c | .h | .hex)\
		make --quiet srcdiff $(wordlist 2, 4, $(MAKECMDGOALS))\
		;;\
	.img )\
		make --quiet hexdiff $(wordlist 2, 4, $(MAKECMDGOALS))\
		;;\
	*)\
		echo "I don't know how to compare filetype $$EXT"\
		;;\
	esac


# Choose between intel|att and 16-bit|32-bot

diffi16 di16 i16:
	make --quiet diff $(wordlist 2, 4, $(MAKECMDGOALS)) ASM=intel BIT=16

diffi32 di32 i32:
	make --quiet diff $(wordlist 2, 4, $(MAKECMDGOALS)) ASM=intel BIT=32

diffa16 da16 a16:
	make --quiet diff $(wordlist 2, 4, $(MAKECMDGOALS)) ASM=att BIT=16

diffa32 da32 a32:
	make --quiet diff $(wordlist 2, 4, $(MAKECMDGOALS)) ASM=att BIT=32

##
## Create bootable USP stick if BIOS needs it
##

%.iso : %.bin
	xorriso -as mkisofs -b $< -o $@ -isohybrid-mbr $< -no-emul-boot -boot-load-size 4 ./

%.img : %.bin
	dd if=/dev/zero of=$@ bs=1024 count=1440
	dd if=$< of=$@ seek=0 conv=notrunc



stick: $(IMG)
	@if test -z "$(DEVICE)"; then \
	echo "*** ATTENTION: make IMG=foo.bin DEVICE=/dev/X"; exit 1; fi 
	dd if=$< of=$(DEVICE)

%/stick: %
	make stick IMG=$* DEVICE=$(wordlist 2, 2, $(MAKECMDGOALS))



.PHONY: clean clean-extra intel att 16 32 diss /diss /i16 /i32 /a16 /a32


# End of Bintools.
# -------------------------------------------------------------


## Self-contained distribution bundle for stand-alone usage.
##
## This rule is meant for SYSeg users to create a stand-alone bundle
## containing a modified copy of a proposed exercise, modified to work
## outside the SYSeg source tree. The user can then copy the exported
## exercise into their own project and develop the implementation challenge.
##
## If the present file is found in an already exported project, this
## rule has no purpose and should not produce any result.
##
##
## make syseg-export    creates a tarball with the essential files, which
##       	        can be distributed independently of the rest of
##			this project.
##
## A pack distribution contain all the items necessary to build and run the
## relevant piece of software. It's useful,a for instance, to bundle
## self-contained subsections of SYSeg meant to be delivered as
## programming exercise assignments or illustrative source code examples.
##		
## In order to select which files should be included in the pack, list them
## in the appropriate variables
## 
## EXPORT_FILES_C    = C files (source, headers, linker scripts)
## EXPORT_FILES_MAKE = Makefiles
## EXPORT_FILES_TEXT = Text files (e.g. README)
## EXPORT_FILES_SH   = Shell scripts (standard /bin/sh)
##
## Except by text files, all other files will have their heading comment
## (the very first comment found in the file) replaced by a corresponding
## standard comments containing boilerplate copyright notice and licensing
## information, with blank fields to be filled in by the pack user.
## Attribution to SYSeg is also included for convenience.

TARNAME=hw



syseg-export export:
	@if ! test -f .dist; then\
	  make do_export;\
	 else\
	  echo "This is a distribution pack already. Nothing to be done.";\
	fi

do_export:
	rm -rf $(TARNAME)
	mkdir $(TARNAME)
	(cd .. && make clean && make)
	for i in $(EXPORT_FILES); do\
	  ../../tools/syseg-export $$i $(TARNAME);\
	done
	touch $(TARNAME)/.dist
	tar zcvf $(TARNAME).tar.gz $(TARNAME)


clean-export:
	rm -f $(TARNAME).tar.gz
	rm -rf $(TARNAME)

.PHONY: syseg-export export clean-export



# Update Makefile from Makefile.m4 if needed, and then invoke make again.
# If the source is from a distribution bundle, the lack of Makefile.m4
# inhibits the updating. 

ifndef UPDATED

Makefile_deps = Makefile.m4 ../../tools/docm4.m4 ../../tools/bintools.m4

Makefile : $(shell if test -f Makefile.m4; then echo $(Makefile_deps); fi);
	@if ! test -f .dist; then\
	  cd .. && make;\
	  make -f Makefile clean;\
	  make -f Makefile UPDATED=1 $(MAKECMDGOAL);\
	fi

endif


