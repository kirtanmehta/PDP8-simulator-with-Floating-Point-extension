/ Program : floating point
/
/
/
/
/
FPCLAC=6550
FPLOAD=6551
FPSTOR=6552
FPADD=6553
FPMULT=6554
/
/
/
*0200
Main,	FPCLAC
		FPLOAD 
		A
		FPADD
		B
		FPSTOR
		C
		FPCLAC
		hlt		
		jmp Main
/
/
/
*0300
A,	0201
	4100
	0000
B,	0206
	6212
	0000
C,
$Main