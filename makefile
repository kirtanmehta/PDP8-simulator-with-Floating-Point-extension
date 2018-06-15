mem:
	bin/pal -v pdp8_fp.as

build:
	vlib bin/work
	vmap work bin/work

compile:
	#cd bin
	vlog +define+debug pdp8.sv
	#cd ..

run:
#	cd bin
	vsim -c -G OBJFILENAME="pdp8_fp.mem" -do "run;exit" PDP8
#	cd ..

all:	mem compile run

clean:
	rm -r kirtan.as
