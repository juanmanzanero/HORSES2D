!
! ///////////////////////////////////////////////////////////////////////////////////////
!
!     SMConstants.F
!
!!
!!     Modification History:
!!       version 0.0 August 10, 2005 David A. Kopriva
!
!     MODULE SMConstants
!
!!        Defines constants for use by the spectral demonstaration
!!        routines, including precision definitions. 
!
!!    @author David A. Kopriva
!
!////////////////////////////////////////////////////////////////////////////////////////
!
      module SMConstants
!
!     *************************************************************************
!           Floating point parameters 
!     *************************************************************************
!
           integer       , parameter, private :: DOUBLE_DIGITS   =  15                                  ! # of desired digits
           integer       , parameter, private :: SINGLE_DIGITS   =  6                                   ! # of desired digits
           integer       , parameter          :: RP              =  SELECTED_REAL_KIND( DOUBLE_DIGITS ) ! Real Kind
           integer       , parameter          :: SP              =  SELECTED_REAL_KIND( SINGLE_DIGITS ) ! Single Real Kind
           integer       , parameter          :: CP              =  SELECTED_REAL_KIND( DOUBLE_DIGITS ) ! Complex Kind
!
!     *************************************************************************
!           Constants
!     *************************************************************************
!
           integer       , parameter          :: FORWARD         = 1
           integer       , parameter          :: BACKWARD       = -1
           integer       , parameter          :: LEFT            = 2
           integer       , parameter          :: RIGHT           = 1
           real(kind=RP) , parameter          :: PI              =  3.141592653589793238462643_RP
           complex(kind=CP)                   :: ImgI            =  ( 0.0_RP, 1.0_RP)                   !                         =  SQRT(-1.0_RP)
!
!     *************************************************************************
!           Interpolation node type aliases              
!     *************************************************************************
!
           integer, parameter                 :: LG              =  1               ! Parameter for Legendre-Gauss nodes
           integer, parameter                 :: LGL             =  2               ! Parameter for Legendre-Gauss-Lobatto nodes
!
!     *************************************************************************
!           Equation type aliases 
!     *************************************************************************
!
           integer, parameter                 :: FORMI           =  1               ! Green form
           integer, parameter                 :: FORMII          =  2               ! Divergence form
!
!
!     *************************************************************************
!           Parameters for I/O
!     *************************************************************************
!
           integer, parameter                 :: STD_OUT         =  6
           integer, parameter                 :: STD_IN          =  5
           integer, parameter                 :: LINE_LENGTH     =  132
!
!     *************************************************************************
!           Boundary conditions and faces classification
!     *************************************************************************
!
           integer, parameter                 :: FACE_INTERIOR   =  0
     
           integer, parameter                 :: PERIODIC_BC     =  0
           integer, parameter                 :: DIRICHLET_BC    =  1
           integer, parameter                 :: EULERWALL_BC    =  2
           integer, parameter                 :: VISCOUSWALL_BC  =  3
           integer, parameter                 :: FARFIELD_BC     =  4
           integer, parameter                 :: OUTFLOW_BC      =  5
           integer, parameter                 :: INFLOWOUTFLOW_BC      =  6
!
!     *************************************************************************
!           Time integration mode
!     *************************************************************************
!             
           integer, parameter                 :: STEADY          =  0
           integer, parameter                 :: TRANSIENT       =  1
     
         contains
            LOGICAL FUNCTION AlmostEqual( a, b ) 
!
!           *************************************+
!              Function by David A. Kopriva
!           *************************************+
!
            IMPLICIT NONE
!
!           ---------
!           Arguments
!           ---------
!
            REAL(KIND=RP) :: a, b
            IF ( a == 0.0_RP .OR. b == 0.0_RP )     THEN
               IF ( ABS(a-b) <= 2*EPSILON(b) )     THEN
                  AlmostEqual = .TRUE.
               ELSE
                  AlmostEqual = .FALSE.
               END IF
            ELSE
               IF( ABS( b - a ) <= 2*EPSILON(b)*MAX(ABS(a), ABS(b)) )     THEN
                  AlmostEqual = .TRUE.
               ELSE
                  AlmostEqual = .FALSE.
               END IF
            END IF
      
            END FUNCTION AlmostEqual

            function ThirdDegreeRoots(a,b,c) result (val)
               implicit none  
               real(kind=RP)              :: a
               real(kind=RP)              :: b
               real(kind=RP)              :: c
               real(kind=RP)              :: val
!              ------------------------------------------------------
               real(kind=RP)              :: p , q
               complex(kind=CP)           :: z1


               p = b - a * a / 3.0_RP
               q = 2.0_RP * a * a * a / 27.0_RP - a * b / 3.0_RP + c
            
               z1 = (( -q + sqrt(q*q + 4.0_RP * p * p * p / 27.0_RP))/2.0_RP)**(1.0_RP / 3.0_RP)         

               val = real(z1 - p / (3.0_RP * z1) - a / 3.0_RP , kind=RP)

            end function ThirdDegreeRoots

      end module SMConstants
