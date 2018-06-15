FPCLAC= 6550
FPLOAD= 6551
FPSTOR= 6552
FPADD= 6553
FPMULT= 6554

*200
Main, FPCLAC
	cla
	tad count
loop, dca count
	FPLOAD
aptr, a
	FPADD
bptr, b
	FPSTOR
cptr, c
	tad aptr
	tad d
	dca aptr
	tad bptr
	tad d
	dca bptr
	tad cptr
	tad d
	dca cptr
	tad count
	tad j
	sma
	jmp loop
	hlt

*250
d,11
j, -1
count, 2
a, 0
0
0
b, 200
0
0
c, 200
0
0
0200
7206
5615
0200
3177
5275
0167
7032
0000
0201
3326
0701
0201
7023
1714
0175
2055
7520
$Main