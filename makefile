FILE ?=  pdp8_fp.mem
ASS_FILE ?= pdp8_fp.as
FORMAT ?= oct
mem:
	bin/pal -v $(ASS_FILE)

build:
	vlib bin/work
	vmap work bin/work

compile:
	#cd bin
	vlog +define+$(FORMAT) pdp8.sv
	#cd ..

run:
#	cd bin
	vsim -c -G OBJFILENAME="$(FILE)" -do "run;exit" PDP8
#	cd ..

all:	mem compile run

help:
	echo "make labe_name FILE=file_name.mem Format=(bin or oct or hex) ASS_FILE=assembly_file.as"
