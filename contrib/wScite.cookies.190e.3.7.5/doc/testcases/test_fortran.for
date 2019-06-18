     PROGRAM MAIN
      INTEGER   I,N,NMAX
      PARAMETER(NMAX=10)
      REAL      COEF(0:NMAX),HORNER,X

   10 CONTINUE
         WRITE(*,*)'Enter the degree of the polynomial'
         READ(*,*)N
      IF (N .GT. NMAX) THEN
         WRITE(*,*)'Degree too large.  Choose smaller value.'
         GO TO 10
      END IF
      WRITE(*,*)'Enter the coefficients in ascending order'
      DO 20, I = 0,N
         WRITE(*,*)'Enter the value for coefficient ',I
         READ(*,*)COEF(I)
   20 CONTINUE
      WRITE(*,*)'Enter the value of X'
      READ(*,*)X
      WRITE(*,*)'The value of the polynomial at ',X,' is ',
     $          HORNER(COEF,N,X)
      STOP 'End of program'
      END

      REAL FUNCTION HORNER(A,N,X)
C This function returns the value of the polynomial 
C y = a_0 + a_1 x + a_2 x^2 + … + a_n x^n
C using Horner's method.
      INTEGER I,N
      REAL    A(0:N),X

      HORNER = A(N)
      D0 10 I = N-1,0,-1
         HORNER = A(I) + HORNER*X
   10 CONTINUE
      END