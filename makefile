mem:
	bin/pal -v mul_test.as

build:
	vlib bin/work
	vmap work bin/work

compile:
	#cd bin
	vlog pdp8.sv
	#cd ..

run:
#	cd bin
	vsim -c -do "run;exit" PDP8
#	cd ..

all:	mem compile run
