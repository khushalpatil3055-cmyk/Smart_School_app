#include<stdio.h>
main()
 { 
    int i,j,n=5;
    for(i=1;j<=n;++i)
    {
        for(j=1; j<=i; ++j)
        {
            printf("*");
        }
        printf("\n");
    }
 }