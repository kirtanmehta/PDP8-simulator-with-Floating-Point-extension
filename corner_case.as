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
2000
0000
0201
5075
3412
0225
4012
4600
0116
4401
4714
0252
6525
2525
0125
1252
5252
0252
2525
2525
0252
2525
2525
0000
0000
0000
0123
1231
1222
0202
4775
3412
0201
2014
4606
$Main
