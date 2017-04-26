#ifdef NAVIER_STOKES

module DGArtificialDissipation
   use SMConstants
   use QuadMeshClass
   use QuadElementClass
   use Physics
   implicit none

#include "Defines.h"


   private
   public   ArtificialDissipation_t    , ArtificialDissipation_Initialization
!
!////////////////////////////////////////////////////////////////////////////
!
!           ARTIFICIAL DISSIPATION CLASSES
!           ------------------------------
!////////////////////////////////////////////////////////////////////////////
!
   type ArtificialDissipation_t
      real(kind=RP)                                              :: Ceps
      procedure(ElementViscosityFCN), private, nopass, pointer   :: ElementViscosity  => NULL()
      procedure(EdgeViscosityFCN),    private, nopass, pointer   :: EdgeViscosity  => NULL()
      contains
         procedure   :: ComputeVolumeFluxes     => ArtificialDissipation_ComputeVolumeFluxes
         procedure   :: ComputeFaceFluxes       => ArtificialDissipation_ComputeFaceFluxes
         procedure   :: ComputeElementViscosity => ArtificialDissipation_ComputeElementViscosity
         procedure   :: ComputeEdgeViscosity    => ArtificialDissipation_ComputeEdgeViscosity
   end type ArtificialDissipation_t

   type, extends(ArtificialDissipation_t)    :: LaplaceDissipation_t
      contains
         procedure   :: ComputeVolumeFluxes  => LaplaceDissipation_ComputeVolumeFluxes
         procedure   :: ComputeFaceFluxes    => LaplaceDissipation_ComputeFaceFluxes
   end type LaplaceDissipation_t

   type, extends(ArtificialDissipation_t)    :: PhysicalDissipation_t
      contains
         procedure   :: ComputeElementViscosity => PhysicalDissipation_ComputeElementViscosity
         procedure   :: ComputeEdgeViscosity    => PhysicalDissipation_ComputeEdgeViscosity
   end type PhysicalDissipation_t

   abstract interface
      pure function ElementViscosityFCN( self , e ) result ( mu )
         use SMConstants
         use QuadElementClass
         import ArtificialDissipation_t
         implicit none
         class(ArtificialDissipation_t),  intent(in)     :: self
         class(QuadElement_t)          ,  intent(in)     :: e
         real(kind=RP)                                   :: mu
      end function ElementViscosityFCN

      pure function EdgeViscosityFCN( self , edge ) result ( mu )
         use SMConstants
         use QuadElementClass
         import ArtificialDissipation_t
         implicit none
         class(ArtificialDissipation_t), intent(in)   :: self
         class(Edge_t)                 , intent(in)   :: edge
         real(kind=RP)                                :: mu(NDIM)
      end function EdgeViscosityFCN
   end interface
!

!  ========
   contains
!  ========
!
!
!//////////////////////////////////////////////////////////////////////////////////////
!
!           INITIALIZATION
!           --------------
!//////////////////////////////////////////////////////////////////////////////////////
!
      function ArtificialDissipation_Initialization() result( ArtificialDissipation )
         use Setup_class
         implicit none
         class(ArtificialDissipation_t), pointer       :: ArtificialDissipation


         if ( Setup % artificialDissipation ) then

            if ( trim( Setup % artificialDissipationType) .eq. "Laplacian" ) then
               allocate    ( LaplaceDissipation_t   :: ArtificialDissipation )
   
            elseif ( trim( Setup % artificialDissipationType) .eq. "Physical" ) then
               allocate    ( PhysicalDissipation_t    :: ArtificialDissipation )

            else
               allocate ( ArtificialDissipation_t  :: ArtificialDissipation ) 

            end if

            if ( trim(Setup % artificialDissipationIndicator) .eq. "Residuals-based" ) then
!               ArtificialDissipation % ElementViscosity => ResidualsBasedElementViscosity
!               ArtificialDissipation % EdgeViscosity    => ResidualsBasedEdgeViscosity

            elseif ( trim(Setup % artificialDissipationIndicator) .eq. "Jumps-based" ) then
               ArtificialDissipation % ElementViscosity => JumpsBasedElementViscosity
               ArtificialDissipation % EdgeViscosity    => JumpsBasedEdgeViscosity

            end if

         else
            allocate ( ArtificialDissipation_t  :: ArtificialDissipation ) 

         end if

         ArtificialDissipation % Ceps = Setup % artificialDissipationIntensity


      end function ArtificialDissipation_Initialization
!
!//////////////////////////////////////////////////////////////////////////////////////
!
!           ARTIFICIAL DISSIPATION PROCEDURES
!           ---------------------------------
!//////////////////////////////////////////////////////////////////////////////////////
!
!TODO: pure
      function ArtificialDissipation_ComputeVolumeFluxes( self , e ) result ( F )
         implicit none
         class(ArtificialDissipation_t), intent (in) :: self
         class(QuadElement_t)      ,     intent (in) :: e
         real(kind=RP)                                :: F( 0 : e % spA % N , 0 : e % spA % N , 1 : NCONS , 1:NDIM)
!
!        ---------------------------
!        The base class does nothing.
!        ---------------------------
!
         F = 0.0_RP

      end function ArtificialDissipation_ComputeVolumeFluxes

      function ArtificialDissipation_ComputeFaceFluxes( self , edge , QL , QR , dQL , dQR , normal ) result ( F )
         implicit none
         class(ArtificialDissipation_t), intent (in) :: self
         class(Edge_t) ,                 intent (in) :: edge
         real(kind=RP)              ,    intent (in) :: QL(0 : edge % spA % N , 1:NCONS)
         real(kind=RP)              ,    intent (in) :: QR(0 : edge % spA % N , 1:NCONS)
         real(kind=RP) ,                 intent (in) :: dQL(0 : edge % spA % N , 1:NDIM , 1:NCONS)
         real(kind=RP) ,                 intent (in) :: dQR(0 : edge % spA % N , 1:NDIM , 1:NCONS)
         real(kind=RP) ,                 intent (in) :: normal(1:NDIM , 0 : edge % spA % N )
         real(kind=RP)                               :: F( 0 : edge % spA % N , 1 : NCONS)
!
!        ---------------------------
!        The base class does nothing.
!        ---------------------------
!
         F = 0.0_RP

      end function ArtificialDissipation_ComputeFaceFluxes

      function ArtificialDissipation_ComputeElementViscosity( self , e ) result ( mu )
         implicit none
         class(ArtificialDissipation_t), intent (in) :: self
         class(QuadElement_t)      ,     intent (in) :: e
         real(kind=RP)                               :: mu
!
!        ---------------------------
!        The base class does nothing.
!        ---------------------------
!
         mu = 0.0_RP

      end function ArtificialDissipation_ComputeElementViscosity
         
      function ArtificialDissipation_ComputeEdgeViscosity( self , ed ) result ( mu )
         implicit none
         class(ArtificialDissipation_t), intent (in) :: self
         class(Edge_t)      ,            intent (in) :: ed
         real(kind=RP)                               :: mu
!
!        ---------------------------
!        The base class does nothing.
!        ---------------------------
!
         mu = 0.0_RP

      end function ArtificialDissipation_ComputeEdgeViscosity

      function LaplaceDissipation_ComputeVolumeFluxes ( self , e ) result ( F )
         implicit none
         class(LaplaceDissipation_t) , intent(in) :: self
         class(QuadElement_t)        , intent(in) :: e
         real(kind=RP)                            :: F( 0 : e % spA % N , 0 : e % spA % N , 1 : NCONS , 1:NDIM)
!
!        ---------------
!        Local variables
!        ---------------
!  
         real(kind=RP)         :: dQ( 0 : e % spA % N , 0 : e % spA % N , 1 : NCONS , 1 : NDIM )
         real(kind=RP)         :: mu

         dQ = e % ComputeInteriorGradient
         mu = self % ElementViscosity(self,e)

         F(:,:,:,IX) = mu * dQ(:,:,IX,:) 
         F(:,:,:,IY) = mu * dQ(:,:,IY,:) 
   
      end function LaplaceDissipation_ComputeVolumeFluxes

      function LaplaceDissipation_ComputeFaceFluxes( self, edge , QL , QR , dQL , dQR , normal) result ( F )
         implicit none
         class(LaplaceDissipation_t), intent(in)      :: self
         class(Edge_t)              , intent(in)      :: edge
         real(kind=RP)              , intent(in)      :: QL(0 : edge % spA % N , 1:NCONS)
         real(kind=RP)              , intent(in)      :: QR(0 : edge % spA % N , 1:NCONS)
         real(kind=RP)              , intent(in)      :: dQL(0 : edge % spA % N , 1:NDIM , 1:NCONS)
         real(kind=RP)              , intent(in)      :: dQR(0 : edge % spA % N , 1:NDIM , 1:NCONS)
         real(kind=RP)              , intent(in)      :: normal(1:NDIM , 0 : edge % spA % N)
         real(kind=RP)                                :: F( 0 : edge % spA % N , 1 : NCONS )
!
!        ---------------
!        Local variables
!        ---------------
!  
         real(kind=RP)  :: mu

         mu = 0.5_RP *  sum(self % EdgeViscosity(self,edge))
         F =  - mu * edge % Area * ( QL - QR ) 

      end function LaplaceDissipation_ComputeFaceFluxes

      pure function PhysicalDissipation_ComputeElementViscosity( self , e ) result ( mu )
         implicit none
         class(PhysicalDissipation_t) , intent(in) :: self
         class(QuadElement_t)         , intent(in) :: e
         real(kind=RP)                             :: mu

         mu = self % ElementViscosity(self,e) 

      end function PhysicalDissipation_ComputeElementViscosity

      pure function PhysicalDissipation_ComputeEdgeViscosity( self , ed ) result ( mu )
         implicit none
         class(PhysicalDissipation_t), intent(in)     :: self
         class(Edge_t)               , intent(in)     :: ed
         real(kind=RP)                                :: mu
         
         mu = maxval(self % EdgeViscosity(self,ed))

      end function PhysicalDissipation_ComputeEdgeViscosity
!
!/////////////////////////////////////////////////////////////////////////////////////////////////
!
!           ARTIFICIAL VISCOSITY ESTIMATORS
!           -------------------------------
!/////////////////////////////////////////////////////////////////////////////////////////////////
!
      pure function JumpsBasedElementViscosity(self , e ) result ( mu )
         implicit none
         class(ArtificialDissipation_t), intent(in)      :: self
         class(QuadElement_t)      , intent(in) :: e
         real(kind=RP)                          :: mu
!
!        ---------------
!        Local variables
!        ---------------
!
         real(kind=RP)            :: gk , gkRHO , gkRHOE
         real(kind=RP)            :: capitalGk
         integer                  :: ed
         real(kind=RP)            :: xiL
         real(kind=RP)            :: xiR
         real(kind=RP)            :: maxVisc
         real(kind=RP)            :: s0
         real(kind=RP), parameter :: k = 5.0_RP
!
!        The jumps indicator is computed squaring all interface jumps
!        ------------------------------------------------------------
         gkRHO =   e % edges(EBOTTOM) % f % computeJumps(IRHO)    &
              + e % edges(ERIGHT ) % f % computeJumps(IRHO)    & 
              + e % edges(ETOP   ) % f % computeJumps(IRHO)    & 
              + e % edges(ELEFT  ) % f % computeJumps(IRHO)   

         gkRHOE = e % edges(EBOTTOM) % f % computeJumps(IRHOE)    &
              + e % edges(ERIGHT ) % f % computeJumps(IRHOE)    & 
              + e % edges(ETOP   ) % f % computeJumps(IRHOE)    & 
              + e % edges(ELEFT  ) % f % computeJumps(IRHOE)   

         gk = max(gkRHO,gkRHOE)

         gk = gk / ( e % edges(EBOTTOM) % f % Area + e % edges(ERIGHT) % f % Area &
                    +e % edges(ETOP) % f % Area + e % edges(ELEFT) % f % Area )

         if ( gk .gt. 1.0e-8 ) then
            gk = log10(gk)
         else
            gk = -HUGE(1.0_RP)
         end if

!
!        Compute the smooth discrete jumps indicator
!        -------------------------------------------
         maxVisc = sqrt(e % Volume)  / ( e % spA % N + 1 )
         s0 = log10( 1.0_RP / ( e % spA % N + 1) ** 4.0_RP ) + 1 

         if ( gk .lt. (s0-k) ) then
            capitalGk = 0.0_RP

         elseif ( gk .lt. (s0+k) ) then
            capitalGk = 0.5_RP * sin( 0.5_RP * PI * ( gk - s0 )/(k) ) + 0.5_RP

         else
            capitalGk = 1.0_RP

         end if

         mu = self % Ceps * maxVisc * capitalGk

      end function JumpsBasedElementViscosity

      pure function JumpsBasedEdgeViscosity( self , ed ) result ( mu )
         implicit none
         class(ArtificialDissipation_t), intent(in) :: self
         class(Edge_t)      , intent(in)   :: ed
         real(kind=RP)                     :: mu(NDIM)

         if ( size( ed % storage ) .eq. 1 ) then
            mu = self % ElementViscosity( self , ed % quads(1) % e )
   
         else
            mu(LEFT)  = self % ElementViscosity( self , ed % quads(LEFT) % e ) 
            mu(RIGHT) = self % ElementViscosity( self , ed % quads(RIGHT) % e ) 

         end if

      end function JumpsBasedEdgeViscosity

!


end module DGArtificialDissipation

#endif
