!#############################################################################
!#                                                                           #
!# fosite - 3D hydrodynamical simulation program                             #
!# module: sources_gravity.f03                                               #
!#                                                                           #
!# Copyright (C) 2014-2018                                                   #
!# Björn Sperling   <sperling@astrophysik.uni-kiel.de>                       #
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
!> \addtogroup gravity
!! - general parameters of gravity group as key-values
!! \key{gtype,INTEGER,Type of gravity source}
!! \key{energy,INTEGER,Add source terms to energy equation?}
!! \key{output/accel,INTEGER,enable(=1) output of acceleration}
!! \key{output/height,INTEGER,enable(=1) output of disc height}
!----------------------------------------------------------------------------!
!> \author Björn Sperling
!! \author Tobias Illenseer
!! \author Jannes Klee
!!
!! \brief generic gravity terms module providing functionaly common to all
!! gravity terms
!----------------------------------------------------------------------------!
MODULE sources_gravity_mod
  USE logging_base_mod
  USE mesh_base_mod
  USE physics_base_mod
  USE sources_base_mod
  USE sources_c_accel_mod
  USE gravity_base_mod
  USE gravity_generic_mod
  USE fluxes_base_mod
  USE boundary_base_mod
  USE common_dict
  IMPLICIT NONE
  !--------------------------------------------------------------------------!
  PRIVATE
  CHARACTER(LEN=32), PARAMETER :: source_name = "gravity"
  TYPE, EXTENDS(sources_c_accel) :: sources_gravity
    CLASS(gravity_base),    POINTER :: glist => null() !< list of gravity terms
    REAL, DIMENSION(:,:,:), POINTER :: height          !< disk scale height
  CONTAINS
    PROCEDURE :: InitSources_gravity
    PROCEDURE :: InfoSources
    PROCEDURE :: ExternalSources_single
    PROCEDURE :: CloseSources
  END TYPE sources_gravity
  ABSTRACT INTERFACE
  END INTERFACE
  !--------------------------------------------------------------------------!
  PUBLIC :: &
       ! types
       sources_gravity
  !--------------------------------------------------------------------------!

CONTAINS

  SUBROUTINE InitSources_gravity(this,Mesh,Physics,Fluxes,config,IO)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(sources_gravity), INTENT(INOUT) :: this
    CLASS(mesh_base),       INTENT(IN)    :: Mesh
    CLASS(fluxes_base),     INTENT(IN)    :: Fluxes
    CLASS(physics_base),    INTENT(IN)    :: Physics
    TYPE(Dict_TYP),         POINTER       :: config, IO
    !------------------------------------------------------------------------!
    INTEGER :: err, stype
    !------------------------------------------------------------------------!
    CALL GetAttr(config,"stype",stype)
    CALL this%InitLogging(stype,source_name)
    CALL this%InitSources(Mesh,Fluxes,Physics,config,IO)

    ! initialize gravity
    CALL new_gravity(this%glist,Mesh,Fluxes,Physics,config,IO)

  END SUBROUTINE InitSources_gravity

  !> Evaluates source-terms by gravitation
  !!
  !! The gravitational source term evaluates all forces that are produced by
  !! gravitational participants.
  SUBROUTINE ExternalSources_single(this,Mesh,Physics,Fluxes,time,dt,pvar,cvar,sterm)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(sources_gravity), INTENT(INOUT) :: this
    CLASS(mesh_base),       INTENT(IN)    :: Mesh
    CLASS(physics_base),    INTENT(INOUT) :: Physics
    CLASS(fluxes_base),     INTENT(IN)    :: Fluxes
    REAL,                   INTENT(IN)    :: time, dt
    REAL, DIMENSION(Mesh%IGMIN:Mesh%IGMAX,Mesh%JGMIN:Mesh%JGMAX,Mesh%KGMIN:Mesh%KGMAX,Physics%VNUM), &
                            INTENT(IN)    :: cvar,pvar
    REAL, DIMENSION(Mesh%IGMIN:Mesh%IGMAX,Mesh%JGMIN:Mesh%JGMAX,Mesh%KGMIN:Mesh%KGMAX,Physics%VNUM), &
                            INTENT(OUT)   :: sterm
    !------------------------------------------------------------------------!
    ! update acceleration of ALL gravity sources
    CALL this%glist%GravitySources(Mesh,Physics,Fluxes,time,dt,pvar,cvar,sterm)
  END SUBROUTINE ExternalSources_single

  SUBROUTINE InfoSources(this,Mesh)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(sources_gravity), INTENT(IN) :: this
    CLASS(mesh_base),       INTENT(IN) :: Mesh
    !------------------------------------------------------------------------!
  END SUBROUTINE InfoSources

  SUBROUTINE CloseSources(this)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(sources_gravity) :: this
    !------------------------------------------------------------------------!
    ! release temporary/global storage
    ! TODO Wait for Lars' solution
  END SUBROUTINE CloseSources

END MODULE sources_gravity_mod