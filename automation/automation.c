/*
 * This code is used to generate the ramdon float point number as well as the assembly code
 */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#define MAX 10

union{
    float f;
    unsigned int n;
} Op1;

union{
    float f;
    unsigned int n;
} Op2;

union{
    float f;
    unsigned int n;
} result;

char *octalformat = "%04o\n";
char *hexformat = "%03x\n";
char *format;

void print_file(FILE *fp, char *format, unsigned int n) 
{
    unsigned int exponent;
    unsigned int upperbits;
    unsigned int lowerbits;

    exponent = (n >> 23) & 0xFF;
    upperbits = ((n >> 12) & 0x7FF) | ((n >> 31) << 11);
    lowerbits = n & 0xFFF;

    fprintf(fp,format,exponent);
    fprintf(fp,format,upperbits);
    fprintf(fp,format,lowerbits);
}

// Generate floating point within provided range
float rfg(float range)
{
    if( (rand() % 100) < 50)
        return ((float)rand()/(float)RAND_MAX) * range * -1;
    else
        return ((float)rand()/(float)RAND_MAX) * range;
}

//============== Assembly Program Strings =================
char *symboldef = "FPCLAC= 6550\n"
                  "FPLOAD= 6551\n"
                  "FPSTOR= 6552\n"
                  "FPADD= 6553\n"
                  "FPMULT= 6554\n\n";

char * LoopHalf1 ="*200\nMain, FPCLAC\n"
                  "\tcla\n\ttad count\n"
                  "loop, dca count\n"
                  "\tFPLOAD\naptr, a\n";

char *fpmult =   "\tFPMULT\nbptr, b\n";
char *fpadd  =   "\tFPADD\nbptr, b\n";

char *LoopHalf2 = "\tFPSTOR\ncptr, c\n"
                  "\ttad aptr\n\ttad d\n\tdca aptr\n"
                  "\ttad bptr\n\ttad d\n\tdca bptr\n"
                  "\ttad cptr\n\ttad d\n\tdca cptr\n"
                  "\ttad count\n\ttad j\n\tsma\n\tjmp loop\n"
                  "\thlt\n\n*250\n";

char * constants_add ="a, 0\n0\n0\n" // 0
                  "b, 200\n0\n0\n"    // 2
                  "c, 200\n0\n0\n";

char * constants_mult ="a, 0\n0\n0\n" // 0
                  "b, 200\n0\n0\n"    // 2
                  "c, 0\n0\n0\n" ;

int main(int argc, char **argv )
{
    FILE *fp;
    float range = 5;
    srand((unsigned int)time(NULL));
    int flag = 0;

    if(argc <= 1)
    {
        fprintf(stdout, "Not enough arguments. \nUsage:\t./automation <op>"
                "\n\top --> FPADD or FPMULT\n\t\n");
        exit(1);
    }
    
    if(!strncmp("FPMULT",argv[1],6))
        flag = 1;
    else if(!strncmp("FPADD",argv[1],6))
        flag = 2;
    else
    {
        fprintf(stderr,"%s is not a valid operation. Use FPADD or FPMULT\n",argv[1]);
        exit(1);
    }
    
    // Print into specified file name
    fp = fopen("kirtan.as","w");
    fprintf(fp,"%s%s",symboldef,LoopHalf1);
    if(flag == 1) // FPMULT
        fprintf(fp,"%s",fpmult);
    else
        fprintf(fp,"%s",fpadd);
    fprintf(fp,"%s",LoopHalf2);
    
    format = octalformat;

    if(flag == 1)
        fprintf(fp,"%s",constants_mult);
    else
        fprintf(fp,"%s",constants_add);
    
    int i;
    for(i = 0; i<MAX; i++)
    {
        Op1.f = rfg(range);
        Op2.f = rfg(range);
        if(flag == 1) // FPMULT
            result.f = Op1.f * Op2.f;
        else          // FPADD
            result.f = Op1.f + Op2.f;
        
        if(flag == 1)
            fprintf(stdout,"%f * %f = %f",Op1.f, Op2.f, result.f);
        else
            fprintf(stdout,"%f + %f = %f",Op1.f, Op2.f, result.f);
        print_file(fp, octalformat, Op1.n);
        print_file(fp, octalformat, Op2.n);
        print_file(fp, octalformat, result.n);
        range = range * 1.5;
    }
    fprintf(fp,"$Main");
    fclose(fp);
    fprintf(stdout,"\n\nAssembly Program generated: %s\n\n\n", argv[1]);
    return 0;
}
