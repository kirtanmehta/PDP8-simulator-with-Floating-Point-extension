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
count, 5
a, 0
0
0
b, 200
0
0
c, 200
0
0
0176
0143
7136
0177
6066
3074
0177
4004
3415
0177
4146
7706
0177
2701
7374
0176
1265
7154
0202
5104
4226
0202
0367
3224
0177
5151
0020
0202
0717
1636
0202
6302
4357
0200
5715
2504
0202
7043
6154
0202
7677
4656
0203
7361
5415
$Main