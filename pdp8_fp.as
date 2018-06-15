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
A,	0203
 	3376
	5605
B,	0170
	1075
 	3412
C,
$Main