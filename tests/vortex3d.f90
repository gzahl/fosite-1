!#############################################################################
!#                                                                           #
!# fosite - 3D hydrodynamical simulation program                             #
!# module: vortex2d.f90                                                      #
!#                                                                           #
!# Copyright (C) 2006-2014                                                   #
!# Tobias Illenseer <tillense@astrophysik.uni-kiel.de>                       #
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
!> 3D isentropic vortex
!! \author Tobias Illenseer
!!
!! References:
!! \cite yee1999
!----------------------------------------------------------------------------!
PROGRAM vortex3d
  USE fosite_mod
#include "tap.h"
  IMPLICIT NONE
  !--------------------------------------------------------------------------!
  ! simulation parameters
  REAL, PARAMETER    :: TSIM    = 30.0     ! simulation stop time
  REAL, PARAMETER    :: GAMMA   = 1.4      ! ratio of specific heats
  REAL, PARAMETER    :: CSISO   = &
!                                   0.0      ! non-isothermal simulation
                                  1.127    ! isothermal simulation
                                           !   with CSISO as sound speed
  ! initial condition (dimensionless units)
  REAL, PARAMETER    :: RHOINF  = 1.       ! ambient density
  REAL, PARAMETER    :: PINF    = 1.       ! ambient pressure
  REAL, PARAMETER    :: VSTR    = 5.0      ! nondimensional vortex strength
  REAL, PARAMETER    :: UINF    = 0.0      ! cartesian components of constant
  REAL, PARAMETER    :: VINF    = 0.0      !   global velocity field
  REAL, PARAMETER    :: WINF    = 0.0
  REAL, PARAMETER    :: X0      = 0.0      ! vortex position (cart. coords.)
  REAL, PARAMETER    :: Y0      = 0.0
  REAL, PARAMETER    :: Z0      = 0.0
  REAL, PARAMETER    :: R0      = 1.0      ! size of vortex
  REAL, PARAMETER    :: OMEGA   = 0.0      ! angular speed of rotational frame
                                           ! around [X0,Y0]
  ! mesh settings
  INTEGER, PARAMETER :: MGEO = CYLINDRICAL
  INTEGER, PARAMETER :: XRES = 40          ! x-resolution
  INTEGER, PARAMETER :: YRES = 40          ! y-resolution
  INTEGER, PARAMETER :: ZRES = 1           ! z-resolution
  REAL, PARAMETER    :: RMIN = 1.0E-2      ! inner radius for polar grids
  REAL, PARAMETER    :: RMAX = 5.0         ! outer radius
  REAL, PARAMETER    :: ZMIN = -1.0        ! extent in z-direction
  REAL, PARAMETER    :: ZMAX = 1.0
  REAL, PARAMETER    :: GPAR = 1.0         ! geometry scaling parameter     !
  ! physics settings
!!$  LOGICAL, PARAMETER :: WITH_IAR = .TRUE.  ! use EULER2D_IAMROT
  LOGICAL, PARAMETER :: WITH_IAR = .FALSE.

  ! output parameters
  INTEGER, PARAMETER :: ONUM = 10           ! number of output data sets
  CHARACTER(LEN=256), PARAMETER &          ! output data dir
                     :: ODIR = './'
  CHARACTER(LEN=256), PARAMETER &          ! output data file name
                     :: OFNAME = 'vortex3d'
  !--------------------------------------------------------------------------!
  CLASS(fosite),ALLOCATABLE :: Sim
  CLASS(marray_compound), POINTER :: pvar_init
  REAL :: sigma
  !--------------------------------------------------------------------------!

  TAP_PLAN(1)

  ALLOCATE(Sim)
  CALL Sim%InitFosite()
  CALL MakeConfig(Sim, Sim%config)
  CALL Sim%Setup()
  CALL InitData(Sim%Mesh, Sim%Physics, Sim%Timedisc)
  CALL Sim%Physics%new_statevector(pvar_init,PRIMITIVE)
  pvar_init = Sim%Timedisc%pvar
  CALL Sim%Run()
  ! compare with initial condition
  sigma = SQRT(SUM((Sim%Timedisc%pvar%data1d(:)-pvar_init%data1d(:))**2)/SIZE(pvar_init%data1d))
  CALL Sim%Finalize()
  CALL pvar_init%Destroy()
  DEALLOCATE(Sim,pvar_init)
  TAP_CHECK_SMALL(sigma,3.8E-2,"vortex3d")
  TAP_DONE

CONTAINS

  SUBROUTINE MakeConfig(Sim, config)
    USE functions, ONLY : ASINH
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    TYPE(fosite)            :: Sim
    TYPE(Dict_TYP),POINTER  :: config
    !------------------------------------------------------------------------!
    ! Local variable declaration
    INTEGER                 :: bc(6)
    TYPE(Dict_TYP), POINTER :: mesh, physics, boundary, datafile, &
                               timedisc, fluxes, sources, rotframe
    REAL                    :: x1,x2,y1,y2,z1,z2
    !------------------------------------------------------------------------!
    INTENT(INOUT)           :: Sim
    !------------------------------------------------------------------------!
    ! mesh settings and boundary conditions
    SELECT CASE(MGEO)
    CASE(CARTESIAN)
       x1 = -RMAX
       x2 =  RMAX
       y1 = -RMAX
       y2 =  RMAX
       bc(WEST)   = NO_GRADIENTS
       bc(EAST)   = NO_GRADIENTS
       bc(SOUTH)  = NO_GRADIENTS
       bc(NORTH)  = NO_GRADIENTS
       bc(BOTTOM) = NO_GRADIENTS
       bc(TOP)    = NO_GRADIENTS
    CASE(CYLINDRICAL)
       x1 = RMIN
       x2 = RMAX
       y1 =  0.0
       y2 =  2.0*PI
       bc(WEST)   = NO_GRADIENTS
       bc(EAST)   = NO_GRADIENTS
       bc(SOUTH)  = PERIODIC
       bc(NORTH)  = PERIODIC
       bc(BOTTOM) = NO_GRADIENTS
       bc(TOP)    = NO_GRADIENTS
    CASE DEFAULT
       CALL Sim%Error("vortex3d::MakeConfig","geometry currently not supported")
    END SELECT
    IF (ZRES.GT.1) THEN
      z1 =  ZMIN
      z2 =  ZMAX
    ELSE
      z1 = 0
      z2 = 0
    END IF

    !mesh settings
    mesh => Dict( &
              "meshtype" / MIDPOINT, &
              "geometry" / MGEO,     &
              "omega"    / OMEGA,    &
              "inum"     / XRES,     &
              "jnum"     / YRES,     &
              "knum"     / ZRES,     &
              "xmin"     / x1,       &
              "xmax"     / x2,       &
              "ymin"     / y1,       &
              "ymax"     / y2,       &
              "zmin"     / z1,       &
              "zmax"     / z2,       &
              "gparam"   / GPAR      )

    ! boundary conditions
    boundary => Dict( &
                "western"   / bc(WEST),   &
                "eastern"   / bc(EAST),   &
                "southern"  / bc(SOUTH),  &
                "northern"  / bc(NORTH),  &
                "bottomer"  / bc(BOTTOM), &
                "topper"    / bc(TOP)     )

    ! physics settings
    IF (CSISO.GT.TINY(CSISO)) THEN
       physics => Dict("problem" / EULER_ISOTHERM, &
                 "cs"      / CSISO)                      ! isothermal sound speed  !
    ELSE
!       IF (WITH_IAR) THEN
!          ! REMARK: the optimal softening parameter depends on mesh geometry, limiter and
!          ! possibly other settings; modify this starting with the default of 1.0, if the
!          ! results show odd behaviour near the center of rotation; larger values increase
!          ! softening; 0.5 give reasonable results for PP limiter on cartesian mesh
!          physics => Dict("problem" / EULER2D_IAMT,        &
!                     "centrot_x"    / X0,"centrot_y" / Y0, & ! center of rotation      !
!                     "softening"    / 0.5,                 & ! softening parameter     !
!                     "gamma"        / GAMMA                ) ! ratio of specific heats !
!       ELSE
          physics => Dict("problem"   / EULER, &
                    "gamma"     / GAMMA)
!       END IF
    END IF

    ! flux calculation and reconstruction method
    fluxes => Dict( &
              "fluxtype"  / KT,        &
!              "order"     / CONSTANT, &
              "order"     / LINEAR,    &
              "variables" / PRIMITIVE, &
              "limiter"   / VANLEER,   &                     ! PP limiter gives better results than
              "theta"     / 1.0E-20,   &                     ! should be < EPS for PP limiter
              "output/slopes" / 0)

    ! activate inertial forces due to rotating frame if OMEGA > 0
    NULLIFY(sources)
    IF (OMEGA.GT.TINY(OMEGA)) THEN
       rotframe => Dict("stype" / ROTATING_FRAME, &
               "x"     / X0, &
               "y"     / Y0)
       sources => Dict("rotframe" / rotframe)
    END IF

    ! time discretization settings
    timedisc => Dict(&
         "method"   / MODIFIED_EULER,   &
         "order"    / 3,                &
         "cfl"      / 0.4,              &
         "stoptime" / TSIM,             &
         "dtlimit"  / 1.0E-4,           &
         "maxiter"  / 1000000,          &
!          "output/fluxes" / 1,          &
         "output/iangularmomentum" / 1, &
         "output/rothalpy" / 1          )

    ! initialize data input/output
    datafile => Dict(&
          "fileformat" / VTK, &
          "filename"   / (TRIM(ODIR) // TRIM(OFNAME)), &
          "count"      / ONUM)

    config => Dict("mesh" / mesh,   &
             "physics"  / physics,  &
             "boundary" / boundary, &
             "fluxes"   / fluxes,   &
             "timedisc" / timedisc, &
             "datafile" / datafile  )

    ! add sources terms
    IF (ASSOCIATED(sources)) &
        CALL SetAttr(config, "sources", sources)

  END SUBROUTINE MakeConfig


  SUBROUTINE InitData(Mesh,Physics,Timedisc)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(physics_base),INTENT(IN)    :: Physics
    CLASS(mesh_base),INTENT(IN)       :: Mesh
    CLASS(timedisc_base),INTENT(INOUT):: Timedisc
    !------------------------------------------------------------------------!
    ! Local variable declaration
    INTEGER           :: n
    REAL, DIMENSION(Mesh%IGMIN:Mesh%IGMAX,Mesh%JGMIN:Mesh%JGMAX,Mesh%KGMIN:Mesh%KGMAX) &
                      :: radius,dist_axis,domega
    REAL, DIMENSION(Mesh%IGMIN:Mesh%IGMAX,Mesh%JGMIN:Mesh%JGMAX,Mesh%KGMIN:Mesh%KGMAX,3) &
                      :: posvec,ephi
    REAL              :: csinf
    !------------------------------------------------------------------------!
    IF (ABS(X0).LE.TINY(X0).AND.ABS(Y0).LE.TINY(Y0).AND.ABS(Z0).LE.TINY(Z0)) THEN
       ! no shift of rotational axis
       radius(:,:,:) = Mesh%radius%bcenter(:,:,:)
       posvec(:,:,:,:) = Mesh%posvec%bcenter(:,:,:,:)
    ELSE
       ! axis is assumed to be parallel to the cartesian z-axis
       ! but shifted in the plane perpendicular to it
       ! compute curvilinear components of shift vector
       posvec(:,:,:,1) = X0
       posvec(:,:,:,2) = Y0
       posvec(:,:,:,3) = 0.0
       CALL Mesh%geometry%Convert2Curvilinear(Mesh%bcenter,posvec,posvec)
       ! subtract the result from the position vector:
       ! this gives you the curvilinear components of all vectors pointing
       ! from the point mass to the bary center of any cell on the mesh
       posvec(:,:,:,:) = Mesh%posvec%bcenter(:,:,:,:) - posvec(:,:,:,:)
       ! compute its absolute value
       radius(:,:,:) = SQRT(posvec(:,:,:,1)**2+posvec(:,:,:,2)**2+posvec(:,:,:,3)**2)
    END IF
    ! distance to axis of rotation
    dist_axis(:,:,:) = SQRT(posvec(:,:,:,1)**2+posvec(:,:,:,2)**2)

    ! curvilinear components of azimuthal unit vector
    ! (maybe with respect to shifted origin)
    ! from ephi = ez x er = ez x posvec/radius = ez x (rxi*exi + reta*eeta)/r
    !             = rxi/r*(ez x exi) + reta/r*(ez x eeta) = rxi/r*eeta - reta/r*exi
    ! because (ez,exi,eeta) is right handed orthonormal set of basis vectors
    ephi(:,:,:,1) = -posvec(:,:,:,2)/radius(:,:,:)
    ephi(:,:,:,2) =  posvec(:,:,:,1)/radius(:,:,:)
    ephi(:,:,:,3) = 0.0

    ! initial condition
    ! angular velocity
    domega(:,:,:) = 0.5*VSTR/PI*EXP(0.5*(1.-(dist_axis(:,:,:)/R0)**2))
    SELECT TYPE(pvar => Timedisc%pvar)
    TYPE IS(statevector_eulerisotherm) ! isothermal HD
      ! density
      pvar%density%data3d(:,:,:)  = RHOINF * EXP(-0.5*(R0*domega(:,:,:)/CSISO)**2)
      ! velocities
      DO n=1,Physics%VDIM
        pvar%velocity%data4d(:,:,:,n) = domega(:,:,:)*dist_axis(:,:,:)*ephi(:,:,:,n)
      END DO
    TYPE IS(statevector_euler) ! non-isothermal HD
      csinf = SQRT(GAMMA*PINF/RHOINF) ! sound speed at infinity (isentropic vortex)
      ! density
      ! ATTENTION: there's a factor of 1/PI missing in the density
      ! formula  eq. (3.3) in [1]
      pvar%density%data3d(:,:,:)  = RHOINF * (1.0 - &
              0.5*(GAMMA-1.0)*(R0*domega/csinf)**2  )**(1./(GAMMA-1.))
      ! pressure
      pvar%pressure%data1d(:) = PINF * (pvar%density%data1d(:)/RHOINF)**GAMMA
      ! velocities
      DO n=1,Physics%VDIM
        pvar%velocity%data4d(:,:,:,n) = domega(:,:,:)*dist_axis(:,:,:)*ephi(:,:,:,n)
      END DO
    END SELECT

    CALL Physics%Convert2Conservative(Timedisc%pvar,Timedisc%cvar)

!     ! compute curvilinear components of constant background velocity field
!     ! and add to the vortex velocity field
!     IF (ABS(UINF).GT.TINY(UINF).OR.ABS(VINF).GT.TINY(VINF).AND.ABS(WINF).LE.TINY(WINF)) THEN
!        v0(:,:,:,1) = UINF
!        v0(:,:,:,2) = VINF
!        v0(:,:,:,3) = WINF
!        CALL Mesh%geometry%Convert2Curvilinear(Mesh%bcenter,v0,v0)
!        Timedisc%pvar%data4d(:,:,:,Physics%XVELOCITY:Physics%ZVELOCITY) = &
!            Timedisc%pvar%data4d(:,:,:,Physics%XVELOCITY:Physics%ZVELOCITY) + v0(:,:,:,1:3)
!     END IF
! 
! 
    CALL Mesh%Info(" DATA-----> initial condition: 3D vortex")
  END SUBROUTINE InitData

END PROGRAM vortex3d
