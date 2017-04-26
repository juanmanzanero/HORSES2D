submodule (Plotter) Paraview
   use SMConstants

#include "Defines.h"

   type LinkedList_t
      integer        :: no_of_entries = 0
      class(Charlist), pointer    :: HEAD => NULL()
      contains
         procedure   :: Destruct => LinkedList_Destruct
   end type LinkedList_t

   type Charlist
      character(len=STR_LEN_PLOTTER)      :: str
      class(Charlist), pointer            :: next => NULL()
   end type Charlist

   integer     :: point_position = 0 
!
!
!  ========
   contains
!  ========
!
      module subroutine Paraview_Initialization ( self )
         use QuadMeshClass
         class(Paraview_t)     :: self

         call Paraview_GatherVariables( self )

      end subroutine Paraview_Initialization
         
      module subroutine Paraview_ExportMesh( self , mesh , Name ) 
         use QuadMeshClass
         implicit none
         class(Paraview_t)        :: self
         class(QuadMesh_t)       :: mesh
         character(len=*)        :: Name
         integer                 :: eID
         character(len=STR_LEN_PLOTTER)      :: auxname

         auxname = Name(1: len_trim(Name) - len(".HiOMesh")) // ".vtk"

         self % Name = trim(auxname)

         call Paraview_OpenFile ( self , isMesh = .true. ) 
         
         write ( self % fID , '(A)') "DATASET UNSTRUCTURED_GRID"

         call Paraview_WriteMesh( self , mesh )

  
         close ( self % fID )

      end subroutine Paraview_ExportMesh

      module subroutine Paraview_Export( self , mesh , Name) 
         use QuadMeshClass
         implicit none
         class(Paraview_t)         :: self
         class(QuadMesh_t)       :: mesh
         character(len=*)        :: Name
         integer                 :: eID

!         self % Name = trim(Name)
!
!         call Paraview_OpenFile ( self , isMesh = .false. )
!
!         do eID = 1 , mesh % no_of_elements
!            call Paraview_NewZone( self , mesh , eID )
!         end do
!
!         close( self % fID )
!
      end subroutine Paraview_Export

      subroutine Paraview_GatherVariables( self ) 
         use Setup_Class
         implicit none
         class(Paraview_t)               :: self
         integer                        :: pos
         character(len=STR_LEN_PLOTTER) :: auxstr
         type(LinkedList_t)             :: entries
         class(CharList), pointer       :: current
         integer                        :: i

         auxstr = Setup % saveVariables

!        Prepare the linked list
!        -----------------------

         do 

            pos = index(auxstr , "_")

            if ( pos .eq. 0 ) then        ! Is not present: All the string is a variable
!
!              Prepare a new entry in the list
!              -------------------------------
               if ( entries % no_of_entries .eq. 0) then
                  allocate( entries % HEAD ) 
                  current => entries % HEAD
               else
                  allocate(current % next)
                  current => current % next
               end if 

               entries % no_of_entries = entries % no_of_entries + 1 
            
               current % str = auxstr
               auxstr        = auxstr
               
               exit

            else
!
!              Prepare a new entry in the list
!              -------------------------------
               if ( entries % no_of_entries .eq. 0) then
                  allocate( entries % HEAD ) 
                  current => entries % HEAD
               else
                  allocate(current % next)
                  current => current % next
               end if 

               entries % no_of_entries = entries % no_of_entries + 1 
            
               current % str = auxstr(1:pos-1)
               auxstr        = auxstr(pos+1:)
            end if
               
         end do

!
!        Store the results in the tecplot typedef
!        ----------------------------------------
         allocate( self % variables ( entries % no_of_entries ) )
         current => entries % HEAD

         self % no_of_variables = entries % no_of_entries
         do i = 1 , entries % no_of_entries
            self % variables(i)  = current % str 
            current => current % next
         end do

      end subroutine Paraview_gatherVariables

      subroutine Paraview_OpenFile( self , IsMesh ) 
         implicit none
         class(Paraview_t)        :: self
         logical                 :: IsMesh
         integer                 :: var

         open( newunit = self % fID , file = trim(self % Name) , status = "unknown" , action = "write" ) 

!
!        Print the header into the file
!        ------------------------------
         write( self % fID , '(A)') "# vtk DataFile Version 2.0"
         write( self % fID , '(A)') trim(self % Name)
         write( self % fID , '(A)') "ASCII"

      end subroutine Paraview_OpenFile

      subroutine Paraview_WriteMesh(self , mesh ) 
         use QuadMeshClass
         use Physics
         implicit none
         class(Paraview_t)        :: self
         class(QuadMesh_t)       :: mesh
!
!        ---------------
!        Local variables
!        ---------------
!
         integer                 :: eID  , npoints , ncells
         integer                 :: iXi , iEta
         integer                 :: var
         real(kind=RP)              :: Q(1:NCONS)


         npoints = 0
         do eID = 1 , mesh % no_of_elements
            npoints = npoints + (mesh % elements(eID) % spA % N + 1)**2
         end do

         write ( self % fID , '(A,I0,A)') "POINTS " , npoints , " float"
        
         do eID = 1 , mesh % no_of_elements
            associate ( N => mesh % elements(eID) % spA % N )
            do iEta = 0 , N
               do iXi = 0 , N
                  write( self % fID , '(F17.10,1X,F17.10,1X,F17.10)') mesh % elements(eID) % x(iXi,iEta,IX) * RefValues % L &
                                                                                 , mesh % elements(eID) % x(iXi,iEta,IY) * RefValues % L &
                                                                                 , 0.0_RP  
               end do
            end do
            end associate
         end do

         write( self % fID , * )    ! One blank line
   
         ncells = 0
         do eID = 1 , mesh % no_of_elements
            ncells = ncells + (mesh % elements(eID) % spA % N)**2
         end do

         write( self % fID , '(A,I0,1X,I0)' ) "CELLS ", ncells,5*ncells

         point_position = -1
         do eID = 1 , mesh % no_of_elements
            associate ( N => mesh % elements(eID) % spA % N )
            do iEta = 1 , N
               do iXi = 1 , N
                  write(self % fID , '(I0,1X,I0,1X,I0,1X,I0,1X,I0)')  4,pointPosition(iXi,iEta,N) + point_position
               end do
            end do
            point_position = point_position + (N+1)*(N+1)
            end associate
         end do

         write( self % fID , * )    ! One blank line
         write( self % fID , '(A,I0)' ) "CELL_TYPES ", ncells
         do eID = 1 , mesh % no_of_elements
            associate ( N => mesh % elements(eID) % spA % N )
            do iEta = 1 , N
               do iXi = 1 , N
                  write(self % fID , '(I0)')  9
               end do
            end do
            end associate
         end do

      end subroutine Paraview_WriteMesh

      subroutine Paraview_NewZone( self , mesh , eID , zoneType) 
         use QuadMeshClass
         use Physics
         use Setup_Class
         implicit none
         class(Paraview_t)        :: self
         class(QuadMesh_t)       :: mesh
         integer                 :: eID 
         character(len=*), optional :: zoneType
         character(len=STR_LEN_PLOTTER)           :: zType
!
!         associate ( N => mesh % elements(eID) % spA % N )
!
!         if ( present ( zoneType ) ) then
!            zType = zoneType
!
!         else
!            zType = trim( Setup % outputType ) 
!   
!         end if
!
!         if ( trim(zType) .eq. "DGSEM" ) then
!            call Paraview_StandardZone( self , mesh , eID )
!         elseif ( trim(zType) .eq. "Interpolated") then
!            call Paraview_InterpolatedZone( self , mesh , eID ) 
!         else
!            print*, "Unknown output type " , trim(Setup % outputType)
!            print*, "Options available are: "
!            print*, "   * DGSEM"
!            print*, "   * Interpolated"
!            stop "Stopped."
!         end if
!
!         end associate
!
      end subroutine  Paraview_NewZone

      subroutine Paraview_StandardZone(self , mesh , eID ) 
         use QuadMeshClass
         use Physics
         implicit none
         class(Paraview_t)        :: self
         class(QuadMesh_t)       :: mesh
         integer                 :: eID 
!        --------------------------------------------------------------------------
         real(kind=RP), pointer  :: rho (:,:) , rhou (:,:) , rhov (:,:) , rhoe (:,:)
         real(kind=RP), pointer  :: rhot(:,:) , rhout(:,:) , rhovt(:,:) , rhoet(:,:)
#ifdef NAVIER_STOKES
         real(kind=RP), target   :: du(0:mesh % elements(eID) % spA % N , 0:mesh % elements(eID) % spA % N , 1:NDIM , 1:NDIM)
         real(kind=RP), pointer  :: ux(:,:) , uy(:,:) , vx(:,:) , vy(:,:)
#endif
         integer                 :: iXi , iEta
         integer                 :: var
         real(kind=RP)              :: Q(1:NCONS)

!         associate ( N => mesh % elements(eID) % spA % N )
!!         
!!        New header
!!        ----------
!         write( self % fID , '(A,I0,A)' , advance="no" ) "ZONE N=",(N+1)*(N+1),", "
!         write( self % fID , '(A,I0,A)' , advance="no" ) "E=",(N)*(N),", "
!         write( self % fID , '(A)'                     ) "DATAPACKING=POINT, ZONETYPE=FEQUADRILATERAL"
!!
!!        Point to the quantities
!!        -----------------------
!         rho(0:,0:)  => mesh % elements(eID) % Q(0:,0:,IRHO) 
!         rhou(0:,0:) => mesh % elements(eID) % Q(0:,0:,IRHOU)
!         rhov(0:,0:) => mesh % elements(eID) % Q(0:,0:,IRHOV)
!         rhoe(0:,0:) => mesh % elements(eID) % Q(0:,0:,IRHOE)
!         rhot(0:,0:)  => mesh % elements(eID) % QDot(0:,0:,IRHO) 
!         rhout(0:,0:) => mesh % elements(eID) % QDot(0:,0:,IRHOU)
!         rhovt(0:,0:) => mesh % elements(eID) % QDot(0:,0:,IRHOV)
!         rhoet(0:,0:) => mesh % elements(eID) % QDot(0:,0:,IRHOE)
!#ifdef NAVIER_STOKES
!   if ( self % no_of_variables .ne. 0 ) then
!         du = getStrainTensor( N , mesh % elements(eID) % Q , mesh % elements(eID) % dQ )
!         ux(0:,0:) => du(0:,0:,IX,IX)
!         uy(0:,0:) => du(0:,0:,IY,IX)
!         vx(0:,0:) => du(0:,0:,IX,IY)
!         vy(0:,0:) => du(0:,0:,IY,IY)
!   end if
!#endif
!
!
!         do iEta = 0 , N
!            do iXi = 0 , N
!               write( self % fID , '(ES17.10,1X,ES17.10,1X,ES17.10)',advance="no") mesh % elements(eID) % x(iXi,iEta,IX) * RefValues % L &
!                                                                              , mesh % elements(eID) % x(iXi,iEta,IY) * RefValues % L &
!                                                                              , 0.0_RP  
!!
!!              Save quantities
!!              ---------------
!               do var = 1 , self % no_of_variables
!
!                  select case ( trim( self % variables(var) ) )
!                     case ("rho")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rho(iXi,iEta) * refValues % rho
!
!                     case ("rhou")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhou(iXi,iEta) * refValues % rho * refValues % a
!
!                     case ("rhov")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhov(iXi,iEta) * refValues % rho * refValues % a
!
!                     case ("rhoe")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhoe(iXi,iEta) * refValues % rho * refValues % p
!
!                     case ("rhot")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhot(iXi,iEta) * refValues % rho / refValues % tc
!
!                     case ("rhout")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhout(iXi,iEta) * refValues % rho * refValues % a / refValues % tc
!
!                     case ("rhovt")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhovt(iXi,iEta) * refValues % rho * refValues % a / refValues % tc
!
!                     case ("rhoet")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhoet(iXi,iEta) * refValues % rho * refValues % p / refValues % tc
!
!                     case ("u")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhou(iXi,iEta)/rho(iXi,iEta) * refValues % a
!
!                     case ("v")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhov(iXi,iEta)/rho(iXi,iEta) * refValues % a
!   
!                     case ("p")
!                        Q = [rho(iXi,iEta) , rhou(iXi,iEta) , rhov(iXi,iEta) , rhoe(iXi,iEta) ]
!                        write(self % fID,'(1X,ES17.10)',advance="no") getPressure( Q ) * refValues % p
!      
!                     case ("Mach")
!                        Q = [rho(iXi,iEta) , rhou(iXi,iEta) , rhov(iXi,iEta) , rhoe(iXi,iEta) ]
!                        write(self % fID,'(1X,ES17.10)',advance="no") sqrt(rhou(iXi,iEta)*rhou(iXi,iEta)+rhov(iXi,iEta)*rhov(iXi,iEta))/rho(iXi,iEta)/ getSoundSpeed( Q )
!
!                     case ("s")
!                        write(self % fID,'(1X,ES17.10)',advance="no") Thermodynamics % gm1 * ( rhoe(iXi,iEta) - &
!                                                  0.5*rhou(iXi,iEta)*rhou(iXi,iEta)/rho(iXi,iEta) - 0.5*rhov(iXi,iEta)*rhov(iXi,iEta)/rho(iXi,iEta) ) &
!                                                    / (rho(iXi,iEta) * refValues % rho)**(Thermodynamics % gamma) * refValues % p
!#ifdef NAVIER_STOKES
!                      case ( "ux" ) 
!                        write(self % fID,'(1X,ES17.10)',advance="no") ux(iXi,iEta) * refValues % a
!
!                      case ( "uy" ) 
!                        write(self % fID,'(1X,ES17.10)',advance="no") uy(iXi,iEta) * refValues % a
!   
!                      case ( "vx" ) 
!                        write(self % fID,'(1X,ES17.10)',advance="no") ux(iXi,iEta) * refValues % a
!
!                      case ( "vy" )
!                        write(self % fID,'(1X,ES17.10)',advance="no") vy(iXi,iEta) * refValues % a
!
!                     case ("vort")
!                        write(self % fID,'(1X,ES17.10)',advance="no") ( vx(iXi,iEta) - uy(iXi,iEta) ) * refValues % a / refValues % L
!#endif
!
!                  end select                        
!
!               end do
!
!!              Jump to next line
!!              -----------------
!               write( self % fID , *)
!
!            end do
!         end do
!
!         write( self % fID , * )    ! One blank line
!
!         do iEta = 1 , N
!            do iXi = 1 , N
!               write(self % fID , '(I0,1X,I0,1X,I0,1X,I0)')  pointPosition(iXi,iEta,N)
!            end do
!         end do
!
!         end associate
!
      end subroutine Paraview_StandardZone

      subroutine Paraview_InterpolatedZone(self , mesh , eID ) 
         use QuadMeshClass
         use Physics
         use Setup_Class
         use MatrixOperations
         use InterpolationAndDerivatives
         implicit none
         class(Paraview_t)        :: self
         class(QuadMesh_t)       :: mesh
         integer                 :: eID 
!        --------------------------------------------------------------------------
         real(kind=RP), pointer     :: rhoDG  (:,:) ,  rhouDG  (:,:) ,  rhovDG  (:,:) ,  rhoeDG  (:,:) 
         real(kind=RP), pointer     :: rhotDG (:,:) ,  rhoutDG (:,:) ,  rhovtDG (:,:) ,  rhoetDG (:,:) 
         real(kind=RP), pointer     :: rho    (:,:) ,  rhou    (:,:) ,  rhov    (:,:) ,  rhoe    (:,:) 
         real(kind=RP), pointer     :: rhot   (:,:) ,  rhout   (:,:) ,  rhovt   (:,:) ,  rhoet   (:,:) 
#ifdef NAVIER_STOKES
         real(kind=RP), target      :: du(0:mesh % elements(eID) % spA % N , 0:mesh % elements(eID) % spA % N , 1:NDIM , 1:NDIM)
         real(kind=RP), pointer     :: uxDG   (:,:) ,  uyDG    (:,:) ,  vxDG    (:,:) ,  vyDG    (:,:)
         real(kind=RP), pointer     :: ux     (:,:) ,  uy      (:,:) ,  vx      (:,:) ,  vy      (:,:)
#endif
         real(kind=RP), allocatable :: xi(:) , T(:,:) , x(:)
         integer                    :: iXi , iEta
         integer                    :: Nout
         integer                    :: var
         real(kind=RP)              :: Q(1:NCONS)

!         associate ( N => mesh % elements(eID) % spA % N , spA => mesh % elements(eID) % spA)
!!
!!        Construct the interpolation framework
!!        -------------------------------------
!         Nout = Setup % no_of_plotPoints - 1
!
!!         
!!        New header
!!        ----------
!         write( self % fID , '(A,I0,A)' , advance="no" ) "ZONE N=",(Nout+1)*(Nout+1),", "
!         write( self % fID , '(A,I0,A)' , advance="no" ) "E=",(Nout)*(Nout),", "
!         write( self % fID , '(A)'                     ) "DATAPACKING=POINT, ZONETYPE=FEQUADRILATERAL"
!
!         allocate( xi ( 0 : Nout ) , T (0 : Nout , 0 : N ) , x(NDIM)) 
!
!         xi = reshape( (/( (1.0_RP * iXi) / Nout , iXi = 0 , Nout )/) , (/Nout + 1/) )
!         call PolynomialInterpolationMatrix( N , Nout , spA % xi , spA % wb , xi , T )
!!
!!        Point to the quantities
!!        -----------------------
!         rhoDG(0:,0:)  => mesh % elements(eID) % Q(0:,0:,IRHO) 
!         rhouDG(0:,0:) => mesh % elements(eID) % Q(0:,0:,IRHOU)
!         rhovDG(0:,0:) => mesh % elements(eID) % Q(0:,0:,IRHOV)
!         rhoeDG(0:,0:) => mesh % elements(eID) % Q(0:,0:,IRHOE)
!         rhotDG(0:,0:)  => mesh % elements(eID) % QDot(0:,0:,IRHO) 
!         rhoutDG(0:,0:) => mesh % elements(eID) % QDot(0:,0:,IRHOU)
!         rhovtDG(0:,0:) => mesh % elements(eID) % QDot(0:,0:,IRHOV)
!         rhoetDG(0:,0:) => mesh % elements(eID) % QDot(0:,0:,IRHOE)
!
!#ifdef NAVIER_STOKES
!      if ( self % no_of_variables .ne. 0 ) then
!         du = getStrainTensor( N , mesh % elements(eID) % Q , mesh % elements(eID) % dQ )
!         uxDG(0:,0:) => du(0:,0:,IX,IX)
!         uyDG(0:,0:) => du(0:,0:,IY,IX)
!         vxDG(0:,0:) => du(0:,0:,IX,IY)
!         vyDG(0:,0:) => du(0:,0:,IY,IY)
!      end if
!#endif
!!
!!        Obtain the interpolation to a new set of equispaced points
!!        ----------------------------------------------------------
!         allocate  (  rho(0:Nout  , 0:Nout) , rhou(0:Nout  , 0:Nout) , rhov(0:Nout  , 0:Nout) , rhoe(0:Nout  , 0:Nout) )
!         allocate  (  rhot(0:Nout , 0:Nout) , rhout(0:Nout , 0:Nout) , rhovt(0:Nout , 0:Nout) , rhoet(0:Nout , 0:Nout) )
!#ifdef NAVIER_STOKES
!         allocate  (  ux(0:Nout , 0:Nout) , uy(0:Nout , 0:Nout) , vx(0:Nout , 0:Nout) , vy(0:Nout,0:Nout) )
!#endif
!         call TripleMatrixProduct ( T , rhoDG   , T , rho   , trC = .true. ) 
!         call TripleMatrixProduct ( T , rhouDG  , T , rhou  , trC = .true. ) 
!         call TripleMatrixProduct ( T , rhovDG  , T , rhov  , trC = .true. ) 
!         call TripleMatrixProduct ( T , rhoeDG  , T , rhoe  , trC = .true. ) 
!         call TripleMatrixProduct ( T , rhotDG  , T , rhot  , trC = .true. ) 
!         call TripleMatrixProduct ( T , rhoutDG , T , rhout , trC = .true. ) 
!         call TripleMatrixProduct ( T , rhovtDG , T , rhovt , trC = .true. ) 
!         call TripleMatrixProduct ( T , rhoetDG , T , rhoet , trC = .true. ) 
!#ifdef NAVIER_STOKES
!         call TripleMatrixProduct ( T , uxDG    , T , ux    , trC = .true. ) 
!         call TripleMatrixProduct ( T , uyDG    , T , uy    , trC = .true. ) 
!         call TripleMatrixProduct ( T , vxDG    , T , vx    , trC = .true. ) 
!         call TripleMatrixProduct ( T , vyDG    , T , vy    , trC = .true. ) 
!#endif
!
!         do iEta = 0 , Nout
!            do iXi = 0 , Nout
!
!               x = mesh % elements(eID) % compute_X ( xi(iXi) , xi(iEta) )
!               write( self % fID , '(ES17.10,1X,ES17.10,1X,ES17.10)',advance="no") x(IX)  * RefValues % L &
!                                                                              , x(IY) * RefValues % L &
!                                                                              , 0.0_RP  
!!
!!              Save quantities
!!              ---------------
!               do var = 1 , self % no_of_variables
!
!                  select case ( trim( self % variables(var) ) )
!                     case ("rho")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rho(iXi,iEta) * refValues % rho
!
!                     case ("rhou")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhou(iXi,iEta) * refValues % rho * refValues % a
!
!                     case ("rhov")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhov(iXi,iEta) * refValues % rho * refValues % a
!
!                     case ("rhoe")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhoe(iXi,iEta) * refValues % rho * refValues % p
!
!                     case ("rhot")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhot(iXi,iEta) * refValues % rho / refValues % tc
!
!                     case ("rhout")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhout(iXi,iEta) * refValues % rho * refValues % a / refValues % tc
!
!                     case ("rhovt")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhovt(iXi,iEta) * refValues % rho * refValues % a / refValues % tc
!
!                     case ("rhoet")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhoet(iXi,iEta) * refValues % rho * refValues % p / refValues % tc
!
!                     case ("u")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhou(iXi,iEta)/rho(iXi,iEta) * refValues % a
!
!                     case ("v")
!                        write(self % fID,'(1X,ES17.10)',advance="no") rhov(iXi,iEta)/rho(iXi,iEta) * refValues % a
!   
!                     case ("p")
!                        Q = [rho(iXi,iEta) , rhou(iXi,iEta) , rhov(iXi,iEta) , rhoe(iXi,iEta) ]
!                        write(self % fID,'(1X,ES17.10)',advance="no") getPressure( Q ) * refValues % p
!      
!                     case ("Mach")
!                        Q = [rho(iXi,iEta) , rhou(iXi,iEta) , rhov(iXi,iEta) , rhoe(iXi,iEta) ]
!                        write(self % fID,'(1X,ES17.10)',advance="no") sqrt(rhou(iXi,iEta)*rhou(iXi,iEta)+rhov(iXi,iEta)*rhov(iXi,iEta))/rho(iXi,iEta)/ getSoundSpeed( Q )
!
!                     case ("s")
!                        write(self % fID,'(1X,ES17.10)',advance="no") Thermodynamics % gm1 * ( rhoe(iXi,iEta) - &
!                                                  0.5*rhou(iXi,iEta)*rhou(iXi,iEta)/rho(iXi,iEta) - 0.5*rhov(iXi,iEta)*rhov(iXi,iEta)/rho(iXi,iEta) ) &
!                                                    / (rho(iXi,iEta) * refValues % rho)**(Thermodynamics % gamma) * refValues % p
!#ifdef NAVIER_STOKES
!                      case ( "ux" ) 
!                        write(self % fID,'(1X,ES17.10)',advance="no") ux(iXi,iEta) * refValues % a
!
!                      case ( "uy" ) 
!                        write(self % fID,'(1X,ES17.10)',advance="no") uy(iXi,iEta) * refValues % a
!   
!                      case ( "vx" ) 
!                        write(self % fID,'(1X,ES17.10)',advance="no") ux(iXi,iEta) * refValues % a
!
!                      case ( "vy" )
!                        write(self % fID,'(1X,ES17.10)',advance="no") vy(iXi,iEta) * refValues % a
!
!                     case ("vort")
!                        write(self % fID,'(1X,ES17.10)',advance="no") ( vx(iXi,iEta) - uy(iXi,iEta) ) * refValues % a / refValues % L
!#endif
!
!                  end select                        
!
!               end do
!
!!              Jump to next line
!!              -----------------
!               write( self % fID , *)
!
!            end do
!         end do
!
!         write( self % fID , * )    ! One blank line
!
!         do iEta = 1 , Nout
!            do iXi = 1 , Nout
!               write(self % fID , '(I0,1X,I0,1X,I0,1X,I0)')  pointPosition(iXi,iEta,Nout)
!            end do
!         end do
!
!         end associate
!
      end subroutine Paraview_InterpolatedZone

      function pointPosition(iXi , iEta , N) result( val )
         implicit none
         integer        :: iXi
         integer        :: iEta
         integer        :: N
         integer        :: val(POINTS_PER_QUAD)

         val(1) = (N+1)*(iEta-1) + iXi + 1
         val(2) = (N+1)*(iEta-1) + iXi 
         val(3) = (N+1)*iEta + iXi
         val(4) = (N+1)*iEta + iXi + 1
      end function pointPosition

      subroutine LinkedList_Destruct( self ) 
         implicit none
         class(LinkedList_t)      :: self
         class(Charlist), pointer :: current
         class(Charlist), pointer :: next
         integer                  :: i

         current => self % head

         do i = 1 , self % no_of_entries
            next => current % next
            deallocate( current )
            current => next

         end do


      end subroutine LinkedList_Destruct

end submodule Paraview  
