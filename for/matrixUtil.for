
Module matrixAlgUtil_Mod
  ! Generic utilities for manipulating vectors and matrices

Contains

  Pure Function Vec2Matrix(vector)
    ! Converts tensors stored in vector format to a matrix format

    Include 'vaba_param.inc'

    ! Arguments
    Double Precision, intent(IN) :: vector(:)

    ! Output
    Double Precision :: Vec2Matrix(3,3)

    ! Locals
    Double Precision, parameter :: zero=0.d0
    ! -------------------------------------------------------------------- !

    Vec2Matrix = zero
    Vec2Matrix(1,1) = vector(1)
    Vec2Matrix(2,2) = vector(2)
    Vec2Matrix(3,3) = Vector(3)
    Vec2Matrix(1,2) = vector(4)

    ! 2D or 3D
    If (size(vector) .GT. 5) Then ! 3D
      Vec2Matrix(2,3) = vector(5)

      ! Symmetric or nonsymmetric
      If (size(vector) .EQ. 6) Then ! 3D, Symmetric
        Vec2Matrix(1,3) = vector(6)

        Vec2Matrix(2,1) = Vec2Matrix(1,2)
        Vec2Matrix(3,2) = Vec2Matrix(2,3)
        Vec2Matrix(3,1) = Vec2Matrix(1,3)

      Else ! 3D, Nonsymmetric
        Vec2Matrix(3,1) = vector(6)
        Vec2Matrix(2,1) = vector(7)
        Vec2Matrix(3,2) = vector(8)
        Vec2Matrix(1,3) = vector(9)
      End If

    Else ! 2D
      If (size(vector) .EQ. 5) Then  ! 2D, Nonsymmetric
        Vec2Matrix(2,1) = vector(5)
      Else                           ! 2D, Symmetric
        Vec2Matrix(2,1) = Vec2Matrix(1,2)
      End If
    End IF

    Return
  End Function Vec2Matrix


  Pure Function Matrix2Vec(mat, nshr)
    ! Converts a symmetric tensor stored in matrix format (3,3) to a vector

    Include 'vaba_param.inc'

    ! Arguments
    Double Precision, intent(IN) :: mat(3,3)
    Integer, intent(IN) :: nshr

    ! Output
    Double Precision :: Matrix2Vec(3+nshr)

    ! Locals
    Double Precision, parameter :: zero=0.d0
    ! -------------------------------------------------------------------- !

    Matrix2Vec = zero

    ! 2D components
    Do I=1,3; Matrix2Vec(I) = mat(I,I); End Do
    Matrix2Vec(4) = mat(1,2)

    ! 3D
    If (nshr .GT. 1) Then
      Matrix2Vec(5) = mat(2,3)
      Matrix2Vec(6) = mat(3,1)
    End If

    Return
  End Function Matrix2Vec


  Pure Function VCmp(vec1, vec2)
    ! Checks if vec1 and vec2 have identical components
    ! Not optimized for large vectors

    ! Arguments
    Double Precision, intent(IN) :: vec1(:), vec2(:)

    ! Output
    Logical :: VCmp

    ! Locals
    Double Precision, parameter :: eps=1.d-30
    ! -------------------------------------------------------------------- !

    If(size(vec1) .NE. size(vec2)) Then
      VCmp = .FALSE.
      Return
    Else
      Do I=1, size(vec1)
        If(abs(vec1(I) - vec2(I)) .GT. eps) Then
          VCmp = .FALSE.
          Return
        End If
      End Do
    End If

    VCmp = .TRUE.

    Return
  End Function VCmp


  Pure Function MInverse(mat)
    ! Finds the inverse of a 3x3 matrix

    Include 'vaba_param.inc'

    ! Arguments
    Double Precision, intent(IN) :: mat(3,3)

    ! Output
    Double Precision :: MInverse(3,3)
    ! -------------------------------------------------------------------- !

    MInverse(1,1) = mat(3,3)*mat(2,2) - mat(3,2)*mat(2,3)
    MInverse(2,2) = mat(3,3)*mat(1,1) - mat(3,1)*mat(1,3)
    MInverse(3,3) = mat(1,1)*mat(2,2) - mat(1,2)*mat(2,1)

    MInverse(1,2) = -(mat(3,3)*mat(1,2) - mat(3,2)*mat(1,3))
    MInverse(2,1) = -(mat(3,3)*mat(2,1) - mat(2,3)*mat(3,1))
    MInverse(1,3) =   mat(2,3)*mat(1,2) - mat(2,2)*mat(1,3)
    MInverse(3,1) =   mat(3,2)*mat(2,1) - mat(2,2)*mat(3,1)
    MInverse(2,3) = -(mat(2,3)*mat(1,1) - mat(2,1)*mat(1,3))
    MInverse(3,2) = -(mat(3,2)*mat(1,1) - mat(1,2)*mat(3,1))

    Do I=1,3
      Do J=1,3
        MInverse(I,J) = MInverse(I,J) / MDet(mat)
      End Do
    End Do

    Return
  End Function MInverse


  Function MInverse6x6(mat)
    ! Finds the inverse of a 6x6 matrix
    ! Requires LAPACK
    ! From: http://fortranwiki.org/fortran/show/inv

    Use forlog_Mod

    Include 'vaba_param.inc'

    ! Arguments
    Double Precision, intent(IN) :: mat(:,:)
    ! Output
    Double Precision :: MInverse6x6(size(mat,1),size(mat,2))

    ! Locals
    Double Precision :: work(size(mat,1))  ! work array for LAPACK
    Integer :: ipiv(size(mat,1))   ! pivot indices
    Integer :: n, out_info
    ! -------------------------------------------------------------------- !

    ! External procedures defined in LAPACK
    Interface
      Subroutine DGETRF(M, N, A, LDA, IPIV, INFO)
        ! http://www.math.utah.edu/software/lapack/lapack-d/dgetrf.html
        Integer, intent(IN) :: M, N, LDA
        Double Precision, intent(INOUT) :: A(LDA,N)
        Integer, intent(OUT) :: IPIV(size(A,1)), INFO
      End Subroutine DGETRF
      Subroutine DGETRI(N, A, LDA, IPIV, WORK, LWORK, INFO)
        ! http://www.math.utah.edu/software/lapack/lapack-d/dgetri.html
        Integer, intent(IN) :: N, LDA, LWORK
        Double Precision, intent(INOUT) :: A(LDA,N)
        Integer, intent(OUT) :: IPIV(size(A,1)), INFO
        Double Precision, intent(OUT) :: WORK(LWORK)
      End Subroutine DGETRI
    End Interface
    ! -------------------------------------------------------------------- !

    ! Store mat in MInverse6x6 to prevent it from being overwritten by LAPACK
    MInverse6x6 = mat
    n = size(mat,1)

    ! DGETRF computes an LU factorization of a general M-by-N matrix A
    ! using partial pivoting with row interchanges.
    Call DGETRF(n, n, MInverse6x6, n, ipiv, out_info)

    If (out_info /= 0) Then
      Call log%error('Matrix is numerically singular!')
    End If

    ! DGETRI computes the inverse of a matrix using the LU factorization
    ! computed by DGETRF.
    call DGETRI(n, MInverse6x6, n, ipiv, work, n, out_info)

    If (out_info /= 0) Then
      Call log%error('Matrix inversion failed!')
    End If

    Return
  End Function MInverse6x6


  Pure Function MDet(mat)
    ! Finds the determinant of a 3x3 matrix

    Include 'vaba_param.inc'

    ! Arguments
    Double Precision, intent(IN) :: mat(3,3)

    ! Output
    Double Precision :: MDet
    ! -------------------------------------------------------------------- !

    MDet = mat(1,1)*(mat(3,3)*mat(2,2) - mat(3,2)*mat(2,3)) - mat(2,1)*(mat(3,3)*mat(1,2) - mat(3,2)*mat(1,3)) + mat(3,1)*(mat(2,3)*mat(1,2) - mat(2,2)*mat(1,3))

    Return
  End Function MDet


  Pure Function OuterProduct(u,v)
    ! Calculates the outer product of two vectors

    Include 'vaba_param.inc'

    ! Arguments
    Double Precision, intent(IN) :: u(:), v(:)

    ! Output
    Double Precision :: OuterProduct(size(u),size(v))
    ! -------------------------------------------------------------------- !

    Do I = 1, size(u)
      Do J = 1, size(v)
        OuterProduct(I,J) = u(I)*v(J)
      End Do
    End Do

    Return
  End Function OuterProduct


  Pure Function CrossProduct(a,b)
    ! Calculates the cross product of two vectors with length 3

    Include 'vaba_param.inc'

    ! Arguments
    Double Precision, intent(IN) :: a(3), b(3)

    ! Output
    Double Precision :: CrossProduct(3)
    ! -------------------------------------------------------------------- !

    CrossProduct(1) = a(2)*b(3) - a(3)*b(2)
    CrossProduct(2) = a(3)*b(1) - a(1)*b(3)
    CrossProduct(3) = a(1)*b(2) - a(2)*b(1)

    Return
  End Function CrossProduct


  Pure Function Norm(u)
    ! Normalizes a vector

    Include 'vaba_param.inc'

    ! Arguments
    Double Precision, intent(IN) :: u(:)

    ! Output
    Double Precision :: Norm(size(u))

    ! Locals
    Double Precision :: u_length
    ! -------------------------------------------------------------------- !

    u_length = Length(u)

    Do I = 1, size(u)
      Norm(I) = u(I)/u_length
    End Do

    Return
  End Function Norm


  Pure Function Length(u)
    ! Calculates the length of a vector

    Include 'vaba_param.inc'

    ! Arguments
    Double Precision, intent(IN) :: u(:)

    ! Output
    Double Precision :: Length
    ! -------------------------------------------------------------------- !

    Length = 0.d0

    Do I = 1, size(u)
      Length = Length + u(I)*u(I)
    End Do

    Length = SQRT(Length)

    Return
  End Function Length


End Module




  ! The following commented out code is here for reference
  ! TO DO: implement into the module above

  ! Subroutine polarDecomp(DFGRD,stretch,rotation)
  !   ! This subroutine returns the stretch and rotation tensors when given
  !   ! a deformation gradient.
  !   ! Meant for use with abaqus implicit
  !   ! Requires LAPACK

  !   include 'vaba_param.inc'

  !   ! -------------------------------------------------------------------- !
  !   ! Arguments
  !   Dimension DFGRD(3,3), stretch(3,3), rotation(3,3)

  !   ! -------------------------------------------------------------------- !
  !   ! Locals
  !   Double precision :: stretchSqrd(3,3), eigVec(3,3), eigVal(3), work(1000), eigDiag(3,3)

  !   Dimension INTV(1),REALV(1)  ! For abaqus warning messages
  !   Character*80 Charv,Message       ! For Abaqus warning messages

  !   Integer ipiv(3),info,lwork

  !   PARAMETER (ZERO = 0.D0)

  !   INTERFACE
  !     Function MInverse(M)
  !       Double Precision, intent(IN) :: M(3,3)
  !       Double Precision :: MInverse(3,3)
  !     end Function
  !   end INTERFACE
  !   ! -------------------------------------------------------------------- !

  !   ! Get the stretch squared (U^2)
  !   stretchSqrd = zero
  !   stretchSqrd = MATMUL(transpose(DFGRD),DFGRD)

  !   ! Get the eigenvalues and eigenvectors of stretch squared
  !   ! DSYEV is a LAPACK function; doc: http://www.netlib.org/lapack/double/dsyev.f
  !   eigVec = stretchSqrd  ! prevent overwrite
  !   ! Setup workspace
  !   LWORK = -1
  !   Call DSYEV( 'V', 'U', 3, eigVec, 3, eigVal, WORK, LWORK, INFO )
  !   LWORK = MIN( 1000, INT( WORK( 1 ) ) )
  !   ! Solve the eigenvalue problem
  !   Call DSYEV( 'V', 'U', 3, eigVec, 3, eigVal, WORK, LWORK, INFO )
  !   if (info .NE. 0) then
  !     ! Message = 'Failed to compute eigenvalues of U^2. DSYEV Error.'
  !     ! Call STDB_ABQERR(-3,Message,intv,realv,charv)
  !     print *, 'WARNING'
  !     print *, 'Failed to compute eigenvalues of U^2. DSYEV Error.'
  !   end if

  !   ! Format sqrt of eigenvalues as a square matrix
  !   eigDiag = zero
  !   eigDiag(1,1) = sqrt(eigVal(1))
  !   eigDiag(2,2) = sqrt(eigVal(2))
  !   eigDiag(3,3) = sqrt(eigVal(3))

  !   ! Get the stretch
  !   stretch = MATMUL(eigVec, MATMUL(eigDiag, TRANSPOSE(eigVec)))

  !   ! Get the rotation (R=F*Inv(U))
  !   rotation = MATMUL(DFGRD,MInverse(stretch))

  !   RETURN
  ! End Subroutine


  ! Subroutine polarDecompExp(defgrad,F,R,U,ndir,nshr)
  !   ! Wrapper for polarDecomp for use in Abaqus implicit
  !   ! defgrad is formated as 1x9 vector
  !   ! Requires LAPACK

  !   include 'vaba_param.inc'

  !   ! -------------------------------------------------------------------- !
  !   ! Arguments
  !   Double Precision, intent(IN) :: defgrad(ndir+nshr+nshr)
  !   Double Precision, intent(OUT) :: F(3,3), U(3,3), R(3,3)
  !   Integer, intent(IN) :: ndir, nshr

  !   ! -------------------------------------------------------------------- !

  !   ! Convert F to 3 x 3 format
  !   F = zero
  !   F(1,1) = defgrad(1)
  !   F(2,2) = defgrad(2)
  !   F(1,2) = defgrad(4)
  !   if (nshr .GT. 1) then
  !     F(3,3) = defgrad(3)
  !     F(2,3) = defgrad(5)
  !     F(3,1) = defgrad(6)
  !     F(2,1) = defgrad(7)
  !     F(3,2) = defgrad(8)
  !     F(1,3) = defgrad(9)
  !   else
  !     F(3,3) = one
  !     F(2,1) = defgrad(5)
  !   end if

  !   Call polarDecomp(F,U,R)

  !   Return
  ! End Subroutine
