!#############################################################################
!#                                                                           #
!# fosite - 3D hydrodynamical simulation program                             #
!# module: sources_generic.f90                                               #
!#                                                                           #
!# Copyright (C) 2007-2013                                                   #
!# Tobias Illenseer <tillense@astrophysik.uni-kiel.de>                       #
!# Björn Sperling   <sperling@astrophysik.uni-kiel.de>                       #
!#                                                                           #
!# This program is free software; you can redistribute it and/or modify      #
!# it under the terms of the GNU General Public License as published by      #
!# the Free Software Foundation; either version 2 of the License, or (at     #
!# your option) any later version.                                           #
!#                                                                           #
!# This program is distributed in the hope that it will be useful, but       #
!# WITHOUT ANY WARRANTY; without even the implied warranty of                #
!# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE, GOOD TITLE or        #
!# NON INFRINGEMENT.  See the GNU General Public License for more            #
!# details.                                                                  #
!#                                                                           #
!# You should have received a copy of the GNU General Public License         #
!# along with this program; if not, write to the Free Software               #
!# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.                 #
!#                                                                           #
!#############################################################################
!----------------------------------------------------------------------------!
!> \addtogroup sources
!!
!! \brief Includes all source terms
!!
!! - general parameters of sources group as key-values
!! \key{stype,INTEGER,Type of source}
!----------------------------------------------------------------------------!
!> \author Tobias Illenseer
!! \author Björn Sperling
!!
!! \brief generic source terms module providing functionaly common
!! to all source terms
!!
!! \ingroup sources
!----------------------------------------------------------------------------!
MODULE sources_base_mod
  USE logging_base_mod
  USE mesh_base_mod
  USE marray_compound_mod
  USE marray_base_mod
  USE gravity_base_mod
  USE physics_base_mod
  USE fluxes_base_mod
  USE common_dict
#if defined(HAVE_FFTW)
  USE fftw
#endif
  IMPLICIT NONE
  !--------------------------------------------------------------------------!
  PRIVATE
  TYPE, ABSTRACT, EXTENDS(logging_base) :: sources_base
     !> \name Variables
     CLASS(sources_base), POINTER    :: next => null() !< next source in list
     REAL                            :: time         !< simulation time
!FIXME
     REAL                            :: mass         !< mass for diskthomson
     REAL                            :: mdot         !< disk accretion rate
     REAL                            :: eps1,eps2    !< softening parameter
     REAL                            :: gparam       !< geometry parameter
     !> effective surface of the dust grains
     REAL                            :: a_eff
     !> optical properties of the disk surface
     REAL                            :: kappa
     REAL                            :: T_star       !< temperature star
     REAL                            :: R_star       !< radius star
     REAL                            :: Qabs         !< dust absorption efficiency
     REAL                            :: T_sublim_min !< dust starts to sublimate
     REAL                            :: cvis         !< viscous Courant no.
     !> dust density = 0.0 due to sublimation
     REAL                            :: T_sublim_max
     !> \name
     !!#### wave_damping
     !> inner and outer wave damping boundaries
     REAL, DIMENSION(2)              :: r
     !> time of a orbital period at the inner and outer boundaries
     REAL, DIMENSION(2)              :: tau
     !> \name
     !!####
     INTEGER                         :: dust_type    !< select mc3d dust catalogue
     !> 1: binary primary component or single star heating
     !! 2: secondary
     INTEGER                         :: star
     LOGICAL                         :: update_disk_height !< enable/disable computation of disk scale height
     TYPE(marray_base)               :: invheight2   !< energy sink due to cooling
     TYPE(marray_base)               :: height       !< energy sink due to cooling
     TYPE(marray_base)               :: h_ext        !< energy sink due to cooling
     REAL, DIMENSION(:,:,:,:), POINTER :: accart        !< acceleration
     REAL, DIMENSION(:,:,:,:), POINTER :: bcposvec,bccart !< position vector
     REAL, DIMENSION(:,:,:), POINTER   :: radius       !< distance to origin
     REAL, DIMENSION(:,:,:), POINTER   :: invr         !< 1./radius
     REAL, DIMENSION(:,:,:), POINTER   :: cs           !< speed of sound
     REAL, DIMENSION(:,:,:), POINTER   :: omega        !< angular velocity
     REAL, DIMENSION(:,:,:,:), POINTER :: omega2       !< Omega Kepler squared
     REAL, DIMENSION(:,:,:), POINTER :: gxr3         !< = GN*x/radius**3
     REAL, DIMENSION(:,:,:), POINTER   :: cellmass     !< rho*dV
     ! --------------------------------------------------------------------- !
     !> \name
     !!#### planet_heating/cooling
     REAL, DIMENSION(:,:), POINTER   :: Energy       !< energy
     REAL, DIMENSION(:,:), POINTER   :: RHO_s        !< surface density
     REAL, DIMENSION(:,:), POINTER   :: P_s          !< surface pressure
     REAL, DIMENSION(:,:), POINTER   :: T_s          !< temperatur
     REAL                            :: tau_inf      !< optical depth
!     REAL                            :: T_0          !< equilibrium temp (also used in diskcooling)
!     REAL                            :: rho_0        !< minimum density
     REAL, DIMENSION(:,:), POINTER   :: T_init       !< initial temperatur
     REAL                            :: intensity
     REAL                            :: albedo
     REAL                            :: distance     !< distance planet<->star
     REAL                            :: R_planet     !< radius planet
     REAL                            :: mu           !< molar mass
     REAL                            :: theta0       !< shifting theta-angle
     REAL                            :: phi0         !< shifting phi-angle
     REAL                            :: omegasun     !< day-night omega
     REAL                            :: year         !< trop. year of a planet
     REAL, DIMENSION(:,:,:), POINTER :: sin1
     REAL                            :: c_p          !< spec. heat cap.
     REAL                            :: gacc         !< grav. acceleration
     REAL                            :: gamma        !< rat. spec. heats
     INTEGER                         :: use_envelope !< enable vicosity envelope
     ! --------------------------------------------------------------------- !
     REAL                            :: Q            !> shearing parameter
     REAL, DIMENSION(:,:), POINTER   :: Sigma_dust   !< dust surface desnity
     REAL, DIMENSION(:,:), POINTER   :: Qstar        !< stellar heating source
     REAL, DIMENSION(:,:), POINTER   :: H_tau1       !< z(tau=1)
     REAL                            :: tau_c        !< cooling time
     REAL, DIMENSION(:,:), POINTER   :: rescale      !< convert tau_z to tau_s
     !> angle between disk surface and line of sight to the star
     REAL, DIMENSION(:,:), POINTER   :: flaring_angle
     !> inverse 3d distance to heating central object
     REAL, DIMENSION(:,:), POINTER   :: invdr_3d
     !> vector from heating central object to mesh points, 3dim
     REAL, DIMENSION(:,:,:), POINTER :: Distance_3d
     REAL, DIMENSION(:,:,:), POINTER :: D_3d_norm    !< nornmalized Distance_3d
     !> normal vector of the disk surface in curvilinear coordinates
     REAL, DIMENSION(:,:,:), POINTER :: n
     REAL, DIMENSION(:,:,:), POINTER :: n_cart       !< cartesian n
     TYPE(marray_base)               :: pot          !< gravitational potential
     !> source terms of sgs module
     REAL, DIMENSION(:,:), POINTER   :: diff,rhoeps,&
                                        sigma
     REAL, DIMENSION(:,:,:), POINTER :: ftxx,ftyy,&
          ftzz,ftxy,ftxz,ftyz
     REAL, DIMENSION(:,:), POINTER   :: delta        !< half-width of the filter
     REAL, DIMENSION(:,:,:), POINTER :: init_pvar    !< pvar state from init
     REAL, DIMENSION(:,:,:), POINTER  :: ptr3        !< 3d pointer
#ifdef HAVE_FFTW
     REAL, DIMENSION(:,:,:), POINTER :: fk, rand     !< forcing (fourier)
     !> \name
     !!#### forcing
     REAL                            :: L,K0,F0,CHI,&
                                        T,invsqrtN,&
                                        stoptime
     TYPE(C_PTR)                     :: plan_r2r     !< fftw plan (real to real)
     REAL(C_DOUBLE), POINTER         :: temp_c(:,:)  !< fftw temp storage
     REAL(C_DOUBLE), POINTER         :: Ftemp_c(:,:)
#endif

  CONTAINS

    PROCEDURE :: InitSources
    PROCEDURE (InfoSources),     DEFERRED :: InfoSources
    PROCEDURE :: CloseSources_all
    PROCEDURE :: ExternalSources
    PROCEDURE (ExternalSources_single), DEFERRED :: ExternalSources_single
    PROCEDURE :: CalcTimestep
    PROCEDURE (CalcTimestep_single),    DEFERRED :: CalcTimestep_single
!    PROCEDURE (SetName),         DEFERRED :: SetName
    PROCEDURE :: GetSourcesPointer

    PROCEDURE :: Finalize_base
    PROCEDURE (Finalize), DEFERRED :: Finalize
  END TYPE sources_base
  ABSTRACT INTERFACE
    SUBROUTINE InfoSources(this,Mesh)
      IMPORT sources_base, Mesh_base
      IMPLICIT NONE
      !------------------------------------------------------------------------!
      CLASS(Sources_base),INTENT(IN) :: this
      CLASS(Mesh_base),INTENT(IN)    :: Mesh
    END SUBROUTINE
    SUBROUTINE Close_Sources(this)
      IMPORT Sources_base
      IMPLICIT NONE
      !------------------------------------------------------------------------!
      CLASS(Sources_base) :: this
      !------------------------------------------------------------------------!
      INTENT(INOUT)     :: this
    END SUBROUTINE
    SUBROUTINE CalcTimestep_single(this,Mesh,Physics,Fluxes,time,pvar,cvar,dt)
      IMPORT Sources_base, Mesh_base, Physics_base, Fluxes_base
      IMPLICIT NONE
      !------------------------------------------------------------------------!
      CLASS(sources_base),INTENT(INOUT) :: this
      CLASS(mesh_base),INTENT(IN)         :: Mesh
      CLASS(physics_base),INTENT(INOUT)   :: Physics
      CLASS(fluxes_base),INTENT(IN)       :: Fluxes
      REAL,INTENT(IN)                     :: time
      REAL, DIMENSION(Mesh%IGMIN:Mesh%IGMAX,Mesh%JGMIN:Mesh%JGMAX,Mesh%KGMIN:Mesh%KGMAX,Physics%VNUM) &
                      :: pvar,cvar
      REAL              :: dt
      !------------------------------------------------------------------------!
      INTENT(IN)        :: pvar,cvar
      INTENT(OUT)       :: dt
    END SUBROUTINE
    SUBROUTINE ExternalSources_single(this,Mesh,Physics,Fluxes,Sources,time,dt,pvar,cvar,sterm)
      IMPORT sources_base, mesh_base, physics_base, fluxes_base, marray_compound
      IMPLICIT NONE
      !------------------------------------------------------------------------!
      CLASS(sources_base),INTENT(INOUT)  :: this
      CLASS(mesh_base),INTENT(IN)        :: Mesh
      CLASS(physics_base),INTENT(INOUT)  :: Physics
      CLASS(sources_base), INTENT(INOUT) :: Sources
      CLASS(fluxes_base),INTENT(IN)      :: Fluxes
      REAL,INTENT(IN)                    :: time, dt
      CLASS(marray_compound),INTENT(INOUT):: pvar,cvar,sterm
    END SUBROUTINE
    SUBROUTINE Finalize(this)
      Import sources_base
      IMPLICIT NONE
      CLASS(sources_base), INTENT(INOUT) :: this
    END SUBROUTINE

  END INTERFACE
  ! tempory storage for source terms
  CLASS(marray_compound), POINTER, SAVE :: temp_sterm => null()
  ! flags for source terms
  INTEGER, PARAMETER :: GRAVITY          = 1
!  INTEGER, PARAMETER :: DISK_THOMSON     = 2
  INTEGER, PARAMETER :: VISCOSITY        = 3
  INTEGER, PARAMETER :: C_ACCEL          = 4
!  INTEGER, PARAMETER :: COOLING          = 5
  INTEGER, PARAMETER :: ROTATING_FRAME   = 20
!  INTEGER, PARAMETER :: SGS              = 23
  INTEGER, PARAMETER :: DISK_COOLING     = 24
!  INTEGER, PARAMETER :: WAVE_DAMPING     = 25
!  INTEGER, PARAMETER :: FORCING          = 26
!  INTEGER, PARAMETER :: PLANET_HEATING   = 27
!  INTEGER, PARAMETER :: PLANET_COOLING   = 28
!  INTEGER, PARAMETER :: STELLAR_HEATING  = 29
  INTEGER, PARAMETER :: SHEARBOX         = 30
  !--------------------------------------------------------------------------!
  PUBLIC :: &
       ! types
       sources_base, &
       ! constants
       VISCOSITY, C_ACCEL, SHEARBOX, GRAVITY, DISK_COOLING, ROTATING_FRAME
  !--------------------------------------------------------------------------!

CONTAINS

  !> Initialize data in sources
  SUBROUTINE InitSources(this,Mesh,Fluxes,Physics,config,IO)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(sources_base), INTENT(IN)    :: this
    CLASS(mesh_base),    INTENT(IN)    :: Mesh
    CLASS(fluxes_base),  INTENT(IN)    :: Fluxes
    CLASS(physics_base), INTENT(IN)    :: Physics
    TYPE(Dict_TYP), POINTER            :: config, IO
    !------------------------------------------------------------------------!
    CALL Physics%new_statevector(temp_sterm,CONSERVATIVE)

    CALL this%Info(" SOURCES--> source term:       " // this%GetName())
    CALL this%InfoSources(Mesh)
  END SUBROUTINE InitSources


  SUBROUTINE ExternalSources(this,Mesh,Fluxes,Physics,time,dt,pvar,cvar,sterm)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(sources_base), TARGET, INTENT(INOUT) :: this
    CLASS(mesh_base),    INTENT(IN)         :: Mesh
    CLASS(fluxes_base),  INTENT(IN)         :: Fluxes
    CLASS(physics_base), INTENT(INOUT)      :: Physics
    REAL,                INTENT(IN)         :: time,dt
    CLASS(marray_compound), INTENT(INOUT)   :: pvar,cvar,sterm
    !------------------------------------------------------------------------!
    CLASS(Sources_base), POINTER :: srcptr
    !------------------------------------------------------------------------!
    ! reset sterm
    sterm%data1d(:) = 0.0
    ! go through all source terms in the list
    srcptr => this
    DO WHILE (ASSOCIATED(srcptr))

      CALL srcptr%ExternalSources_single(Mesh,Physics,Fluxes,this,time,dt,pvar,cvar,temp_sterm)

      ! add to the sources
      sterm%data1d(:) = sterm%data1d(:) + temp_sterm%data1d(:)
      ! next source term
      srcptr => srcptr%next

    END DO
    ! reset ghost cell data
    IF (Mesh%GINUM.GT.0) THEN
      sterm%data4d(Mesh%IGMIN:Mesh%IMIN-Mesh%IP1,:,:,:) = 0.0
      sterm%data4d(Mesh%IMAX+Mesh%IP1:Mesh%IGMAX,:,:,:) = 0.0
    END IF
    IF (Mesh%GJNUM.GT.0) THEN
      sterm%data4d(:,Mesh%JGMIN:Mesh%JMIN-Mesh%JP1,:,:) = 0.0
      sterm%data4d(:,Mesh%JMAX+Mesh%JP1:Mesh%JGMAX,:,:) = 0.0
    END IF
    IF (Mesh%GKNUM.GT.0) THEN
      sterm%data4d(:,:,Mesh%KGMIN:Mesh%KMIN-Mesh%KP1,:) = 0.0
      sterm%data4d(:,:,Mesh%KMAX+Mesh%KP1:Mesh%KGMAX,:) = 0.0
    END IF
  END SUBROUTINE ExternalSources


  SUBROUTINE CalcTimestep(this,Mesh,Physics,Fluxes,time,pvar,cvar,dt,dtcause)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(sources_base), TARGET, INTENT(IN)    :: this
    CLASS(mesh_base),            INTENT(IN)    :: Mesh
    CLASS(physics_base),         INTENT(INOUT) :: Physics
    CLASS(fluxes_base),          INTENT(IN)    :: Fluxes
    REAL              :: time
    REAL, DIMENSION(Mesh%IGMIN:Mesh%IGMAX,Mesh%JGMIN:Mesh%JGMAX,Mesh%KGMIN:Mesh%KGMAX,Physics%VNUM) &
                      :: pvar,cvar
    REAL              :: dt
    INTEGER           :: dtcause
    !------------------------------------------------------------------------!
    CLASS(Sources_base), POINTER :: srcptr
    REAL              :: dt_new
    !------------------------------------------------------------------------!
    INTENT(IN)        :: time,pvar,cvar
    INTENT(INOUT)     :: dt,dtcause
    !------------------------------------------------------------------------!
    dt_new = dt

    ! go through all source terms in the list
    srcptr => this
    DO WHILE(ASSOCIATED(srcptr))

       CALL srcptr%CalcTimestep_single(Mesh,Physics,Fluxes,time,pvar,cvar,dt_new)

       IF (dt_new .LT. dt) dtcause=srcptr%GetType()
       dt = MIN(dt,dt_new)
       ! next source term
       srcptr => srcptr%next
    END DO
  END SUBROUTINE CalcTimestep

  !> \public
  FUNCTION GetSourcesPointer(list,stype) RESULT(sp)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(sources_base), TARGET, INTENT(IN) :: list
    CLASS(sources_base), POINTER :: sp
    INTEGER, INTENT(IN)          :: stype
    !------------------------------------------------------------------------!
    sp => list
    DO
       IF (ASSOCIATED(sp).EQV..FALSE.) EXIT
!CDIR IEXPAND
       IF (sp%GetType().EQ.stype) RETURN
       sp => sp%next
    END DO
  END FUNCTION GetSourcesPointer

  SUBROUTINE CloseSources_all(this,Fluxes)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(sources_base), TARGET, INTENT(IN) :: this
    CLASS(fluxes_base),          INTENT(IN) :: Fluxes
    !------------------------------------------------------------------------!
    CLASS(sources_base), POINTER            :: srcptr
    !------------------------------------------------------------------------!
    ! call deallocation procedures for all source terms
    DO
       srcptr => this
       IF (.NOT.ASSOCIATED(srcptr)) EXIT
       srcptr => srcptr%next
       IF (.NOT.srcptr%Initialized()) &
            CALL srcptr%Error("CloseSources","not initialized")
!       CALL srcptr%Finalize()
       DEALLOCATE(srcptr)
    END DO
  END SUBROUTINE CloseSources_all

  !> Destructor
  SUBROUTINE Finalize_base(this)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(sources_base) :: this
    !------------------------------------------------------------------------!
    IF (.NOT.this%Initialized()) &
        CALL this%Error("CloseSources","not initialized")

    IF(ASSOCIATED(temp_sterm)) THEN
      IF (ASSOCIATED(temp_sterm%data1d)) CALL temp_sterm%Destroy()
      DEALLOCATE(temp_sterm)
      NULLIFY(temp_sterm)
    END IF
  END SUBROUTINE Finalize_base

END MODULE sources_base_mod
