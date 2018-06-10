mem:
	bin/pal -v pdp8_fp.as

build:
	vlib bin/work
	vmap work bin/work

compile:
	#cd bin
	vlog bin/pdp8.v
	#cd ..

run:
	cd bin
	vsim -c -do "run;exit" PDP8
	cd ..

all:	mem compile run