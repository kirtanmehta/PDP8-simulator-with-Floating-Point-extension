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
		FPMULT
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
A,	0177
	1000
	0000
B,	0200
	3000
	0000
C,
$Main