!#############################################################################
!#                                                                           #
!# fosite - 3D hydrodynamical simulation program                             #
!# module: geometry_logspherical.f90                                         #
!#                                                                           #
!# Copyright (C) 2007-2018                                                   #
!# Tobias Illenseer <tillense@astrophysik.uni-kiel.de>                       #
!# Jannes Klee      <jklee@astrophysik.uni-kiel.de>                          #
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
!> \author Tobias Illenseer
!! \author Jannes Klee
!!
!! \brief defines properties of a 3D logspherical mesh
!----------------------------------------------------------------------------!
MODULE geometry_logspherical_mod
  USE geometry_base_mod
  USE geometry_spherical_mod, ONLY: geometry_spherical
  USE common_dict
  IMPLICIT NONE
  !--------------------------------------------------------------------------!
  TYPE, EXTENDS(geometry_spherical) :: geometry_logspherical
  CONTAINS
    PROCEDURE :: InitGeometry_logspherical
    PROCEDURE :: ScaleFactors_1
    PROCEDURE :: ScaleFactors_2
    PROCEDURE :: ScaleFactors_3
    PROCEDURE :: ScaleFactors_4
    PROCEDURE :: Radius_1
    PROCEDURE :: Radius_2
    PROCEDURE :: Radius_3
    PROCEDURE :: Radius_4
    PROCEDURE :: PositionVector_1
    PROCEDURE :: PositionVector_2
    PROCEDURE :: PositionVector_3
    PROCEDURE :: PositionVector_4
    PROCEDURE :: Convert2Cartesian_coords_1
    PROCEDURE :: Convert2Cartesian_coords_2
    PROCEDURE :: Convert2Cartesian_coords_3
    PROCEDURE :: Convert2Cartesian_coords_4
    PROCEDURE :: Convert2Curvilinear_coords_1
    PROCEDURE :: Convert2Curvilinear_coords_2
    PROCEDURE :: Convert2Curvilinear_coords_3
    PROCEDURE :: Convert2Curvilinear_coords_4
    PROCEDURE :: Finalize
  END TYPE
  PRIVATE
  CHARACTER(LEN=32), PARAMETER :: geometry_name = "logspherical"
  !--------------------------------------------------------------------------!
  PUBLIC :: geometry_logspherical
  !--------------------------------------------------------------------------!

CONTAINS

  SUBROUTINE InitGeometry_logspherical(this,config)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(INOUT) :: this
    TYPE(DICT_TYP),POINTER                   :: config
    !------------------------------------------------------------------------!
    REAL                                     :: gparam
    !------------------------------------------------------------------------!
    CALL GetAttr(config, "gparam", gparam, 1.0)

    CALL this%SetScale(gparam)
    CALL this%InitGeometry(LOGSPHERICAL,geometry_name,config)
    CALL this%SetAzimuthIndex(3)
  END SUBROUTINE InitGeometry_logspherical

  PURE SUBROUTINE ScaleFactors_1(this,coords,hx,hy,hz)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, INTENT(IN),  DIMENSION(:,:) :: coords
    REAL, INTENT(OUT), DIMENSION(:)   :: hx,hy,hz
    !------------------------------------------------------------------------!
    CALL ScaleFactors(this%geoparam(1),coords(:,1),coords(:,2),coords(:,3), &
                      hx(:),hy(:),hz(:))
  END SUBROUTINE ScaleFactors_1

  PURE SUBROUTINE ScaleFactors_2(this,coords,hx,hy,hz)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, INTENT(IN),  DIMENSION(:,:,:) :: coords
    REAL, INTENT(OUT), DIMENSION(:,:)   :: hx,hy,hz
    !------------------------------------------------------------------------!
    CALL ScaleFactors(this%geoparam(1),coords(:,:,1),coords(:,:,2), &
                      coords(:,:,3),hx(:,:),hy(:,:),hz(:,:))
  END SUBROUTINE ScaleFactors_2

  PURE SUBROUTINE ScaleFactors_3(this,coords,hx,hy,hz)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, INTENT(IN),  DIMENSION(:,:,:,:) :: coords
    REAL, INTENT(OUT), DIMENSION(:,:,:)   :: hx,hy,hz
    !------------------------------------------------------------------------!
    CALL ScaleFactors(this%geoparam(1),coords(:,:,:,1),coords(:,:,:,2), &
                      coords(:,:,:,3),hx(:,:,:),hy(:,:,:),hz(:,:,:))
  END SUBROUTINE ScaleFactors_3

  PURE SUBROUTINE ScaleFactors_4(this,coords,hx,hy,hz)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, INTENT(IN),  DIMENSION(:,:,:,:,:) :: coords
    REAL, INTENT(OUT), DIMENSION(:,:,:,:)   :: hx,hy,hz
    !------------------------------------------------------------------------!
    CALL ScaleFactors(this%geoparam(1),coords(:,:,:,:,1),coords(:,:,:,:,2), &
                      coords(:,:,:,:,3),hx(:,:,:,:),hy(:,:,:,:),hz(:,:,:,:))
  END SUBROUTINE ScaleFactors_4

  PURE SUBROUTINE Radius_1(this,coords,r)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, DIMENSION(:,:), INTENT(IN) :: coords
    REAL, DIMENSION(:),  INTENT(OUT) :: r
    !------------------------------------------------------------------------!
    r = Radius(this%geoparam(1),coords(:,1))
  END SUBROUTINE Radius_1

  PURE SUBROUTINE Radius_2(this,coords,r)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, DIMENSION(:,:,:), INTENT(IN) :: coords
    REAL, DIMENSION(:,:),  INTENT(OUT) :: r
    !------------------------------------------------------------------------!
    r = Radius(this%geoparam(1),coords(:,:,1))
  END SUBROUTINE Radius_2

  PURE SUBROUTINE Radius_3(this,coords,r)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, DIMENSION(:,:,:,:), INTENT(IN) :: coords
    REAL, DIMENSION(:,:,:),  INTENT(OUT) :: r
    !------------------------------------------------------------------------!
    r = Radius(this%geoparam(1),coords(:,:,:,1))
  END SUBROUTINE Radius_3

  PURE SUBROUTINE Radius_4(this,coords,r)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, DIMENSION(:,:,:,:,:), INTENT(IN) :: coords
    REAL, DIMENSION(:,:,:,:),  INTENT(OUT) :: r
    !------------------------------------------------------------------------!
    r = Radius(this%geoparam(1),coords(:,:,:,:,1))
  END SUBROUTINE Radius_4

  PURE SUBROUTINE PositionVector_1(this,coords,posvec)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN)  :: this
    REAL, DIMENSION(:,:), INTENT(IN)  :: coords
    REAL, DIMENSION(:,:), INTENT(OUT) :: posvec
    !------------------------------------------------------------------------!
    CALL PositionVector(this%geoparam(1),coords(:,1),posvec(:,1), &
                        posvec(:,2),posvec(:,3))
  END SUBROUTINE PositionVector_1

  PURE SUBROUTINE PositionVector_2(this,coords,posvec)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN)  :: this
    REAL, DIMENSION(:,:,:), INTENT(IN)  :: coords
    REAL, DIMENSION(:,:,:), INTENT(OUT) :: posvec
    !------------------------------------------------------------------------!
    CALL PositionVector(this%geoparam(1),coords(:,:,1),posvec(:,:,1), &
                        posvec(:,:,2),posvec(:,:,3))
  END SUBROUTINE PositionVector_2

  PURE SUBROUTINE PositionVector_3(this,coords,posvec)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN)  :: this
    REAL, DIMENSION(:,:,:,:), INTENT(IN)  :: coords
    REAL, DIMENSION(:,:,:,:), INTENT(OUT) :: posvec
    !------------------------------------------------------------------------!
    CALL PositionVector(this%geoparam(1),coords(:,:,:,1),posvec(:,:,:,1), &
                        posvec(:,:,:,2),posvec(:,:,:,3))
  END SUBROUTINE PositionVector_3

  PURE SUBROUTINE PositionVector_4(this,coords,posvec)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN)  :: this
    REAL, DIMENSION(:,:,:,:,:), INTENT(IN)  :: coords
    REAL, DIMENSION(:,:,:,:,:), INTENT(OUT) :: posvec
    !------------------------------------------------------------------------!
    CALL PositionVector(this%geoparam(1),coords(:,:,:,:,1),posvec(:,:,:,:,1), &
                        posvec(:,:,:,:,2),posvec(:,:,:,:,3))
  END SUBROUTINE PositionVector_4

  PURE SUBROUTINE Convert2Cartesian_coords_1(this,curv,cart)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, DIMENSION(:,:), INTENT(IN)  :: curv
    REAL, DIMENSION(:,:), INTENT(OUT) :: cart
    !------------------------------------------------------------------------!
    CALL Convert2Cartesian_coords(this%geoparam(1),curv(:,1),curv(:,2),curv(:,3), &
                                  cart(:,1),cart(:,2),cart(:,3))
  END SUBROUTINE Convert2Cartesian_coords_1

  PURE SUBROUTINE Convert2Cartesian_coords_2(this,curv,cart)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, DIMENSION(:,:,:), INTENT(IN)  :: curv
    REAL, DIMENSION(:,:,:), INTENT(OUT) :: cart
    !------------------------------------------------------------------------!
    CALL Convert2Cartesian_coords(this%geoparam(1),curv(:,:,1),curv(:,:,2),curv(:,:,3), &
                                  cart(:,:,1),cart(:,:,2),cart(:,:,3))
  END SUBROUTINE Convert2Cartesian_coords_2

  PURE SUBROUTINE Convert2Cartesian_coords_3(this,curv,cart)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, DIMENSION(:,:,:,:), INTENT(IN)  :: curv
    REAL, DIMENSION(:,:,:,:), INTENT(OUT) :: cart
    !------------------------------------------------------------------------!
    CALL Convert2Cartesian_coords(this%geoparam(1),curv(:,:,:,1),curv(:,:,:,2),curv(:,:,:,3), &
                                  cart(:,:,:,1),cart(:,:,:,2),cart(:,:,:,3))
  END SUBROUTINE Convert2Cartesian_coords_3

  PURE SUBROUTINE Convert2Cartesian_coords_4(this,curv,cart)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, DIMENSION(:,:,:,:,:), INTENT(IN)  :: curv
    REAL, DIMENSION(:,:,:,:,:), INTENT(OUT) :: cart
    !------------------------------------------------------------------------!
    CALL Convert2Cartesian_coords(this%geoparam(1),curv(:,:,:,:,1),curv(:,:,:,:,2),curv(:,:,:,:,3), &
                                  cart(:,:,:,:,1),cart(:,:,:,:,2),cart(:,:,:,:,3))
  END SUBROUTINE Convert2Cartesian_coords_4

  PURE SUBROUTINE Convert2Curvilinear_coords_1(this,cart,curv)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, DIMENSION(:,:), INTENT(IN)  :: cart
    REAL, DIMENSION(:,:), INTENT(OUT) :: curv
    !------------------------------------------------------------------------!
    CALL Convert2Curvilinear_coords(this%geoparam(1),cart(:,1),cart(:,2),cart(:,3), &
                                    curv(:,1),curv(:,2),curv(:,3))
  END SUBROUTINE Convert2Curvilinear_coords_1

  PURE SUBROUTINE Convert2Curvilinear_coords_2(this,cart,curv)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, DIMENSION(:,:,:), INTENT(IN)  :: cart
    REAL, DIMENSION(:,:,:), INTENT(OUT) :: curv
    !------------------------------------------------------------------------!
    CALL Convert2Curvilinear_coords(this%geoparam(1),cart(:,:,1),cart(:,:,2),cart(:,:,3), &
                                    curv(:,:,1),curv(:,:,2),curv(:,:,3))
  END SUBROUTINE Convert2Curvilinear_coords_2

  PURE SUBROUTINE Convert2Curvilinear_coords_3(this,cart,curv)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, DIMENSION(:,:,:,:), INTENT(IN)  :: cart
    REAL, DIMENSION(:,:,:,:), INTENT(OUT) :: curv
    !------------------------------------------------------------------------!
    CALL Convert2Curvilinear_coords(this%geoparam(1),cart(:,:,:,1),cart(:,:,:,2),cart(:,:,:,3), &
                                    curv(:,:,:,1),curv(:,:,:,2),curv(:,:,:,3))
  END SUBROUTINE Convert2Curvilinear_coords_3

  PURE SUBROUTINE Convert2Curvilinear_coords_4(this,cart,curv)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, DIMENSION(:,:,:,:,:), INTENT(IN)  :: cart
    REAL, DIMENSION(:,:,:,:,:), INTENT(OUT) :: curv
    !------------------------------------------------------------------------!
    CALL Convert2Curvilinear_coords(this%geoparam(1),cart(:,:,:,:,1),cart(:,:,:,:,2),cart(:,:,:,:,3), &
                                    curv(:,:,:,:,1),curv(:,:,:,:,2),curv(:,:,:,:,3))
  END SUBROUTINE Convert2Curvilinear_coords_4

  !> Reference: \cite bronstein2008 , Tabelle 13.1
  ELEMENTAL SUBROUTINE Convert2Cartesian_vectors_0(this,xi,eta,phi,vxi,veta,vphi,vx,vy,vz)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, INTENT(IN)                      :: xi,eta,phi,vxi,veta,vphi
    REAL, INTENT(OUT)                     :: vx,vy,vz
    !------------------------------------------------------------------------!
    vx = vxi*SIN(eta)*COS(phi) + veta*COS(eta)*COS(phi) - vphi*SIN(phi)
    vy = vxi*SIN(eta)*SIN(phi) + veta*COS(eta)*SIN(phi) + vphi*COS(phi)
    vz = vxi*COS(eta) - veta*SIN(eta)
  END SUBROUTINE Convert2Cartesian_vectors_0

  !> Reference: \cite bronstein2008 , Tabelle 13.1
  ELEMENTAL SUBROUTINE Convert2Curvilinear_vectors_0(this,xi,eta,phi,vx,vy,vz,vxi,veta,vphi)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(IN) :: this
    REAL, INTENT(IN)                      :: xi,eta,phi,vx,vy,vz
    REAL, INTENT(OUT)                     :: vxi,veta,vphi
    !------------------------------------------------------------------------!
    vxi  = vx*SIN(eta)*COS(phi) + vy*SIN(eta)*SIN(phi) + vz*COS(eta)
    veta = vx*COS(eta)*COS(phi) + vy*COS(eta)*SIN(phi) - vz*SIN(eta)
    vphi = -vx*SIN(phi) + vy*COS(phi)
  END SUBROUTINE Convert2Curvilinear_vectors_0

  SUBROUTINE Finalize(this)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(geometry_logspherical), INTENT(INOUT) :: this
    !------------------------------------------------------------------------!
    CALL this%Finalize_base()
  END SUBROUTINE Finalize

  ELEMENTAL SUBROUTINE ScaleFactors(gp,logr,theta,phi,hlogr,htheta,hphi)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    REAL, INTENT(IN)  :: gp,logr,theta,phi
    REAL, INTENT(OUT) :: hlogr,htheta,hphi
    !------------------------------------------------------------------------!
    hlogr  = gp*EXP(logr)
    htheta = hlogr
    hphi   = hlogr * SIN(theta)
  END SUBROUTINE ScaleFactors

  ELEMENTAL FUNCTION Radius(gp,logr)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    REAL, INTENT(IN)  :: gp,logr
    REAL :: Radius
    !------------------------------------------------------------------------!
    Radius = gp*EXP(logr)
  END FUNCTION Radius

  ELEMENTAL SUBROUTINE PositionVector(gp,logr,rx,ry,rz)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    REAL, INTENT(IN)  :: gp,logr
    REAL, INTENT(OUT) :: rx,ry,rz
    !------------------------------------------------------------------------!
    rx = Radius(gp,logr)
    ry = 0.0
    rz = 0.0
  END SUBROUTINE PositionVector

  ELEMENTAL SUBROUTINE Convert2Cartesian_coords(gp,logr,theta,phi,x,y,z)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    REAL, INTENT(IN)  :: gp,logr,theta,phi
    REAL, INTENT(OUT) :: x,y,z
    !------------------------------------------------------------------------!
    REAL :: r
    !------------------------------------------------------------------------!
    r = gp*EXP(logr)
    x = r*SIN(theta)*COS(phi)
    y = r*SIN(theta)*SIN(phi)
    z = r*COS(theta)
  END SUBROUTINE Convert2Cartesian_coords

  ELEMENTAL SUBROUTINE Convert2Curvilinear_coords(gp,x,y,z,logr,theta,phi)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    REAL, INTENT(IN)  :: gp,x,y,z
    REAL, INTENT(OUT) :: logr,theta,phi
    !------------------------------------------------------------------------!
    REAL :: r
    !------------------------------------------------------------------------!
    r = SQRT(x*x+y*y+z*z)
    logr = LOG(r/gp)
    theta = ACOS(z/r)
    phi = ATAN2(y,x)
    IF(phi.LT.0.0) THEN
        phi = phi + 2.0*PI
    END IF
  END SUBROUTINE Convert2Curvilinear_coords

END MODULE geometry_logspherical_mod
