!#############################################################################
!#                                                                           #
!# fosite - 3D hydrodynamical simulation program                             #
!# module: mesh_midpoint.f90                                                 #
!#                                                                           #
!# Copyright (C) 2006-2012                                                   #
!# Tobias Illenseer <tillense@astrophysik.uni-kiel.de>                       #
!# Manuel Jung                                                               #
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
!! \author Manuel Jung
!!
!! \brief mesh module for midpoint quadrature rule
!!
!! \extends mesh_common
!! \ingroup mesh
!----------------------------------------------------------------------------!
MODULE mesh_midpoint_mod
  USE mesh_base_mod
  USE common_dict
  IMPLICIT NONE
  !--------------------------------------------------------------------------!
  TYPE, EXTENDS(mesh_base) :: mesh_midpoint
    PRIVATE
  CONTAINS
    PRIVATE
      PROCEDURE, PUBLIC :: VectorDivergence2D_1
!      PROCEDURE :: VectorDivergence2D_2
      PROCEDURE, PUBLIC :: TensorDivergence2D_1
!      PROCEDURE :: TensorDivergence2D_2
      PROCEDURE, PUBLIC:: TensorDivergence3D
      PROCEDURE, PUBLIC:: VectorDivergence3D
      PROCEDURE, PUBLIC :: InitMesh_midpoint
      PROCEDURE, PUBLIC :: Finalize
  END TYPE mesh_midpoint
  ! exclude interface block from doxygen processing
  !> \cond InterfaceBlock
  !> \endcond
  !--------------------------------------------------------------------------!
  PRIVATE
  CHARACTER(LEN=32), PARAMETER :: mesh_name = "midpoint"
  !--------------------------------------------------------------------------!
  PUBLIC :: &
       ! constants
#ifdef PARALLEL
       DEFAULT_MPI_REAL, &
#endif
       ! types
       mesh_midpoint
  !--------------------------------------------------------------------------!

CONTAINS

  SUBROUTINE InitMesh_midpoint(this,config,IO)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(mesh_midpoint),INTENT(INOUT) :: this
    TYPE(Dict_TYP),POINTER             :: config,IO
    !------------------------------------------------------------------------!
    INTEGER                            :: err
    !------------------------------------------------------------------------!

    ! basic mesh and geometry initialization
    CALL this%InitMesh(config, IO, MIDPOINT, mesh_name)

    ! allocate memory for pointers that are specific for midpoint fluxes
    ALLOCATE( &
           this%dAx(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,this%KGMIN:this%KGMAX,2), &
           this%dAy(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,this%KGMIN:this%KGMAX,2), &
           this%dAz(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,this%KGMIN:this%KGMAX,2), &
           this%dAxdydz(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,this%KGMIN:this%KGMAX,2), &
           this%dAydzdx(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,this%KGMIN:this%KGMAX,2), &
           this%dAzdxdy(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,this%KGMIN:this%KGMAX,2), &
             STAT=err)
    IF (err.NE.0) THEN
       CALL this%Error("InitMesh_midpoint", "Unable to allocate memory.")
    END IF

    ! surface elements divided by dxdy or dydz or dzdx
    ! perpendicular to x-direction
    this%dAxdydz(:,:,:,1:2) = this%hy%faces(:,:,:,1:2)*this%hz%faces(:,:,:,1:2)
    ! perpendicular to y-direction
    this%dAydzdx(:,:,:,1:2) = this%hz%faces(:,:,:,3:4)*this%hx%faces(:,:,:,3:4)
    ! perpendicular to z-direction
    this%dAzdxdy(:,:,:,1:2) = this%hx%faces(:,:,:,5:6)*this%hy%faces(:,:,:,5:6)

    ! surface elements
    this%dAx(:,:,:,:) = this%dAxdydz(:,:,:,:)*this%dy*this%dz    ! perpendicular to x-direction
    this%dAy(:,:,:,:) = this%dAydzdx(:,:,:,:)*this%dz*this%dx    ! perpendicular to y-direction
    this%dAz(:,:,:,:) = this%dAzdxdy(:,:,:,:)*this%dx*this%dy    ! perpendicular to z-direction

    ! volume elements = hx*hy*hz*dx*dy*dz
    this%volume%data3d(:,:,:) = this%sqrtg%center(:,:,:)*this%dx*this%dy*this%dz

    ! inverse volume elements multiplied by dxdy or dydz or dzdx
    this%dxdydV%data1d(:) = this%dx*this%dy/(this%volume%data1d(:)+TINY(this%dx))
    this%dydzdV%data1d(:) = this%dy*this%dz/(this%volume%data1d(:)+TINY(this%dy))
    this%dzdxdV%data1d(:) = this%dz*this%dx/(this%volume%data1d(:)+TINY(this%dz))

    ! commutator coefficients (geometric center values)
    this%cyxy%center(:,:,:) = 0.5*(this%hz%faces(:,:,:,2)+this%hz%faces(:,:,:,1)) &
         * (this%hy%faces(:,:,:,2)-this%hy%faces(:,:,:,1)) * this%dydzdV%data3d(:,:,:)
    this%cyzy%center(:,:,:) = 0.5*(this%hx%faces(:,:,:,6)+this%hx%faces(:,:,:,5)) &
         * (this%hy%faces(:,:,:,6)-this%hy%faces(:,:,:,5)) * this%dxdydV%data3d(:,:,:)
    this%cxyx%center(:,:,:) = 0.5*(this%hz%faces(:,:,:,4)+this%hz%faces(:,:,:,3)) &
         * (this%hx%faces(:,:,:,4)-this%hx%faces(:,:,:,3)) * this%dzdxdV%data3d(:,:,:)
    this%cxzx%center(:,:,:) = 0.5*(this%hy%faces(:,:,:,6)+this%hy%faces(:,:,:,5)) &
         * (this%hx%faces(:,:,:,6)-this%hx%faces(:,:,:,5)) * this%dxdydV%data3d(:,:,:)
    this%czxz%center(:,:,:) = 0.5*(this%hy%faces(:,:,:,2)+this%hy%faces(:,:,:,1)) &
         * (this%hz%faces(:,:,:,2)-this%hz%faces(:,:,:,1)) * this%dydzdV%data3d(:,:,:)
    this%czyz%center(:,:,:) = 0.5*(this%hx%faces(:,:,:,4)+this%hx%faces(:,:,:,3)) &
         * (this%hz%faces(:,:,:,4)-this%hz%faces(:,:,:,3)) * this%dzdxdV%data3d(:,:,:)

    ! set bary center values to geometric center values
    this%cyxy%bcenter(:,:,:) = this%cyxy%center(:,:,:)
    this%cyzy%bcenter(:,:,:) = this%cyzy%center(:,:,:)
    this%cxyx%bcenter(:,:,:) = this%cxyx%center(:,:,:)
    this%cxzx%bcenter(:,:,:) = this%cxzx%center(:,:,:)
    this%czxz%bcenter(:,:,:) = this%czxz%center(:,:,:)
    this%czyz%bcenter(:,:,:) = this%czyz%center(:,:,:)

    ! center line elements
    this%dlx%data3d(:,:,:) = this%hx%center(:,:,:)*this%dx
    this%dly%data3d(:,:,:) = this%hy%center(:,:,:)*this%dy
    this%dlz%data3d(:,:,:) = this%hz%center(:,:,:)*this%dz
  END SUBROUTINE InitMesh_midpoint


  ! computes the cell centered curvilinear vector divergence
  ! for cell centered 2D vector components vx,vy on the whole mesh
  ! except for the outermost boundary cells
  PURE SUBROUTINE VectorDivergence2D_1(this,vx,vy,divv)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(mesh_midpoint),INTENT(IN) :: this
    REAL, DIMENSION(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,this%KGMIN:this%KGMAX) &
                      :: vx,vy,divv
    !------------------------------------------------------------------------!
    INTEGER           :: i,j,k
    !------------------------------------------------------------------------!
    INTENT(IN)        :: vx,vy
    INTENT(OUT)       :: divv
    !------------------------------------------------------------------------!
    ! we simply use the 3D tensor divergence and set the commutator coefficients
    ! and the off-diagonal tensor components to 0
!NEC$ IVDEP
    DO k=this%KGMIN+this%KP1,this%KGMAX-this%KP1
      DO j=this%JGMIN+this%JP1,this%JGMAX-this%JP1
!NEC$ IVDEP
        DO i=this%IGMIN+this%IP1,this%IGMAX-this%IP1
          divv(i,j,k) = Divergence3D( &
                             this%dAxdydz(i,j,k,1),this%dAxdydz(i,j,k,2), &
                             this%dAydzdx(i,j,k,1),this%dAydzdx(i,j,k,2), &
                             this%dAzdxdy(i,j,k,1),this%dAzdxdy(i,j,k,2), &
                             this%dxdydV%data3d(i,j,k),this%dzdxdV%data3d(i,j,k),this%dydzdV%data3d(i,j,k), &
                             0.0,0.0,0.0,0.0, & ! no commutator coefficients
                             0.5*(vx(i-1,j,k)+vx(i,j,k)),0.5*(vx(i+1,j,k)+vx(i,j,k)), &
                             0.5*(vy(i,j-1,k)+vy(i,j,k)),0.5*(vy(i,j+1,k)+vy(i,j,k)), &
                             0.0, 0.0,  &
                             0.0,0.0,0.0,0.0)   ! no off-diagonal tensor components
        END DO
      END DO
    END DO
  END SUBROUTINE VectorDivergence2D_1


!  ! computes the cell centered curvilinear vector divergence
!  ! for 2D vector v given on the 4 face centered positions
!  PURE SUBROUTINE VectorDivergence2D_2(this,v,divv)
!    IMPLICIT NONE
!    !------------------------------------------------------------------------!
!    CLASS(mesh_midpoint),INTENT(IN) :: this
!    REAL, DIMENSION(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,4,2) &
!                      :: v
!    REAL, DIMENSION(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX) &
!                      :: divv
!    !------------------------------------------------------------------------!
!    INTEGER           :: i,j
!    !------------------------------------------------------------------------!
!    INTENT(IN)        :: v
!    INTENT(OUT)       :: divv
!    !------------------------------------------------------------------------!
!    ! we simply use the 3D tensor divergence and set all commutator coefficients
!    ! and the tensor components Tyx, Tyy, Tzz to zero
!!NEC$ IVDEP
!    DO j=this%JGMIN,this%JGMAX
!!NEC$ IVDEP
!      DO i=this%IGMIN,this%IGMAX
!         divv(i,j) = Divergence3D(this%dAxdy(i,j,1),this%dAxdy(i,j,2), &
!                                 this%dAydx(i,j,1),this%dAydx(i,j,2), &
!                                 this%dxdV(i,j),this%dydV(i,j), &
!                                 0.0,0.0,0.0, & ! vanishing commutator coefficients
!                                 v(i,j,WEST,1),v(i,j,EAST,1), &
!                                 v(i,j,SOUTH,2),v(i,j,NORTH,2), &
!                                 0.0,0.0,0.0)   ! vanishing tensor components
!      END DO
!    END DO
!  END SUBROUTINE VectorDivergence2D_2
!

  ! computes the cell centered curvilinear tensor divergence on the whole mesh
  ! except for the outermost boundary cells
  ! input: 2D rank 2 tensor T with components Txx,Txy,Tyx,Tyy given at cell centers
  ! output: 2D vector vector components divTx,divTy
  PURE SUBROUTINE TensorDivergence2D_1(this,Txx,Txy,Tyx,Tyy,divTx,divTy)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(mesh_midpoint),INTENT(IN)   :: this
    REAL, DIMENSION(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,this%KGMIN:this%KGMAX) &
                      :: Txx,Txy,Tyx,Tyy,divTx,divTy
    !------------------------------------------------------------------------!
    INTEGER           :: i,j,k
    !------------------------------------------------------------------------!
    INTENT(IN)        :: Txx,Txy,Tyx,Tyy
    INTENT(OUT)       :: divTx,divTy
    !------------------------------------------------------------------------!
    ! we simply use the 3D tensor divergence and set the commutator coefficient
    ! and the tensor component related to the z-direction to zero
    DO k=this%KGMIN+this%KP1,this%KGMAX-this%KP1
!NEC$ IVDEP
      DO j=this%JGMIN+this%JP1,this%JGMAX-this%JP1
!NEC$ IVDEP
        DO i=this%IGMIN+this%IP1,this%IGMAX-this%IP1
         ! x component of tensor divergence
         divTx(i,j,k) = Divergence3D(this%dAxdydz(i,j,k,1),this%dAxdydz(i,j,k,2), &
                                 this%dAydzdx(i,j,k,1),this%dAydzdx(i,j,k,2), &
                                 this%dAzdxdy(i,j,k,1),this%dAzdxdy(i,j,k,2), &
                                 this%dxdydV%data3d(i,j,k),this%dzdxdV%data3d(i,j,k),this%dydzdV%data3d(i,j,k), &
                                 this%cxyx%center(i,j,k),this%cyxy%center(i,j,k), &
                                 0.0,0.0, & ! czxz = 0 and cxzx = 0 because of 2D
                                 0.5*(Txx(i-1,j,k)+Txx(i,j,k)),0.5*(Txx(i+1,j,k)+Txx(i,j,k)), &
                                 0.5*(Txy(i,j-1,k)+Txy(i,j,k)),0.5*(Txy(i,j+1,k)+Txy(i,j,k)), &
                                 0.0, 0.0, & ! difference at Bottom and Top faces is 0 because of 2D
                                 Tyx(i,j,k),Tyy(i,j,k),0.0,0.0) ! Tzz = 0 and Tzx = 0 because of 2D
         ! y component of tensor divergence
         divTy(i,j,k) = Divergence3D(this%dAxdydz(i,j,k,1),this%dAxdydz(i,j,k,2), &
                                 this%dAydzdx(i,j,k,1),this%dAydzdx(i,j,k,2), &
                                 this%dAzdxdy(i,j,k,1),this%dAzdxdy(i,j,k,2), &
                                 this%dxdydV%data3d(i,j,k),this%dzdxdV%data3d(i,j,k),this%dydzdV%data3d(i,j,k), &
                                 -this%cxyx%center(i,j,k),-this%cyxy%center(i,j,k), &
                                 0.0,0.0, & ! czyz = 0 and cyzy = 0 because of 2D
                                 0.5*(Tyx(i-1,j,k)+Tyx(i,j,k)),0.5*(Tyx(i+1,j,k)+Tyx(i,j,k)), &
                                 0.5*(Tyy(i,j-1,k)+Tyy(i,j,k)),0.5*(Tyy(i,j+1,k)+Tyy(i,j,k)), &
                                 0.0, 0.0, & ! difference at Bottom and Top faces is 0 because of 2D
                                 Txx(i,j,k),Txy(i,j,k),0.0,0.0) ! Tzz = 0 and Tzy = 0 because of 2D
        END DO
      END DO
    END DO
  END SUBROUTINE TensorDivergence2D_1


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! ATTENTION: TensorDivergence2D_2 is untested, use with care
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!  ! computes the cell centered curvilinear tensor divergence
!  ! input: 2D rank 2 tensor T given on the 4 face centered positions
!  ! output: 2D vector divT
!  PURE SUBROUTINE TensorDivergence2D_2(this,T,divT)
!    IMPLICIT NONE
!    !------------------------------------------------------------------------!
!    CLASS(mesh_midpoint),INTENT(IN) :: this
!    REAL, DIMENSION(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,4,2,2) :: T
!    REAL, DIMENSION(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,2)   :: divT
!    !------------------------------------------------------------------------!
!    REAL              :: Txx,Txy,Tyx,Tyy
!    INTEGER           :: i,j
!    !------------------------------------------------------------------------!
!    INTENT(IN)        :: T
!    INTENT(OUT)       :: divT
!    !------------------------------------------------------------------------!
!    ! we simply use the 3D tensor divergence and set the commutator coefficient
!    ! and the tensor component related to the z-direction to zero
!!NEC$ IVDEP
!    DO j=this%JGMIN,this%JGMAX
!!NEC$ IVDEP
!      DO i=this%IGMIN,this%IGMAX
!         ! compute mean value of all four face values to obtain cell centered values
!         Txx = 0.25*SUM(T(i,j,:,1,1))
!         Txy = 0.25*SUM(T(i,j,:,1,2))
!         Tyx = 0.25*SUM(T(i,j,:,2,1))
!         Tyy = 0.25*SUM(T(i,j,:,2,2))
!         ! x component of tensor divergence
!         divT(i,j,1) = Divergence3D(this%dAxdy(i,j,1),this%dAxdy(i,j,2), &
!                                 this%dAydx(i,j,1),this%dAydx(i,j,2), &
!                                 this%dxdV(i,j),this%dydV(i,j), &
!                                 this%cxyx%center(i,j),this%cyxy%center(i,j), &
!                                 0.0, & ! czxz = 0 because of 2D
!                                 T(i,j,WEST,1,1),T(i,j,EAST,1,1), &
!                                 T(i,j,SOUTH,1,2),T(i,j,NORTH,1,2), &
!                                 Tyx,Tyy,0.0) ! Tzz = 0 because of 2D
!         ! y component of tensor divergence
!         divT(i,j,2) = Divergence3D(this%dAxdy(i,j,1),this%dAxdy(i,j,2), &
!                                 this%dAydx(i,j,1),this%dAydx(i,j,2), &
!                                 this%dxdV(i,j),this%dydV(i,j), &
!                                 -this%cxyx%center(i,j),-this%cyxy%center(i,j), &
!                                 0.0, & ! czyz = 0 because of 2D
!                                 T(i,j,WEST,2,1),T(i,j,EAST,2,1), &
!                                 T(i,j,SOUTH,2,2),T(i,j,NORTH,2,2), &
!                                 Txx,Txy,0.0) ! Tzz = 0 because of 2D
!      END DO
!    END DO
!  END SUBROUTINE TensorDivergence2D_2


  ! computes the cell centered curvilinear vector divergence
  ! for cell centered 3D vector components vx,vy,vz on the whole mesh
  ! except for the outermost boundary cells
  PURE SUBROUTINE VectorDivergence3D(this,vx,vy,vz,divv)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(mesh_midpoint),INTENT(IN) :: this
    REAL, DIMENSION(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,this%KGMIN:this%KGMAX) &
                      :: vx,vy,vz,divv
    !------------------------------------------------------------------------!
    INTEGER           :: i,j,k
    !------------------------------------------------------------------------!
    INTENT(IN)        :: vx,vy,vz
    INTENT(OUT)       :: divv
    !------------------------------------------------------------------------!
    ! we simply use the 3D tensor divergence and set the commutator coefficients
    ! and the off-diagonal tensor components to 0
    DO k=this%KGMIN+this%KP1,this%KGMAX-this%KP1
!NEC$ IVDEP
      DO j=this%JGMIN+this%JP1,this%JGMAX-this%JP1
!NEC$ IVDEP
        DO i=this%IGMIN+this%IP1,this%IGMAX-this%IP1
          divv(i,j,k) = Divergence3D(this%dAxdydz(i,j,k,1),this%dAxdydz(i,j,k,2), &
                                     this%dAydzdx(i,j,k,1),this%dAydzdx(i,j,k,2), &
                                     this%dAzdxdy(i,j,k,1),this%dAzdxdy(i,j,k,2), &
                                     this%dxdydV%data3d(i,j,k),this%dzdxdV%data3d(i,j,k),this%dydzdV%data3d(i,j,k), &
                                     0.0,0.0,0.0,0.0, & ! no commutator coefficients
                                     0.5*(vx(i-1,j,k)+vx(i,j,k)),0.5*(vx(i+1,j,k)+vx(i,j,k)), &
                                     0.5*(vy(i,j-1,k)+vy(i,j,k)),0.5*(vy(i,j+1,k)+vy(i,j,k)), &
                                     0.5*(vz(i,j,k-1)+vz(i,j,k)),0.5*(vz(i,j,k+1)+vz(i,j,k)), &
                                     0.0,0.0,0.0,0.0)   ! no off-diagonal tensor components
        END DO
      END DO
    END DO
  END SUBROUTINE VectorDivergence3D



  ! computes the cell centered tensor divergence in curvilinear coordinates with
  ! symmetry along the z-direction on the whole mesh except for the outermost
  ! boundary cells
  ! input: 3D rank 2 tensor T with components Txx,Txy,Txz,Tyx,Tyy,Tyz,Tzx,Tzy,Tzz
  !        given at cell centers
  ! output: 3D vector vector components divTx,divTy,divTz
  PURE SUBROUTINE TensorDivergence3D(this,Txx,Txy,Txz,Tyx,Tyy,Tyz,Tzx,Tzy,Tzz, &
                                     divTx,divTy,divTz)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(mesh_midpoint), INTENT(IN) :: this
    REAL, DIMENSION(this%IGMIN:this%IGMAX,this%JGMIN:this%JGMAX,this%KGMIN:this%KGMAX) &
                      :: Txx,Txy,Txz,Tyx,Tyy,Tyz,Tzx,Tzy,Tzz,divTx,divTy,divTz
    !------------------------------------------------------------------------!
    INTEGER           :: i,j,k
    !------------------------------------------------------------------------!
    INTENT(IN)        :: Txx,Txy,Txz,Tyx,Tyy,Tyz,Tzx,Tzy,Tzz
    INTENT(OUT)       :: divTx,divTy,divTz
    !------------------------------------------------------------------------!
!NEC$ IVDEP
    DO k=this%KGMIN+this%KP1,this%KGMAX-this%KP1
!NEC$ IVDEP
       DO j=this%JGMIN+this%JP1,this%JGMAX-this%JP1
!NEC$ IVDEP
          DO i=this%IGMIN+this%IP1,this%IGMAX-this%IP1
             ! x component of tensor divergence
             divTx(i,j,k) = Divergence3D(this%dAxdydz(i,j,k,1),this%dAxdydz(i,j,k,2),                                 &
                                         this%dAydzdx(i,j,k,1),this%dAydzdx(i,j,k,2),                                 &
                                         this%dAzdxdy(i,j,k,1),this%dAzdxdy(i,j,k,2),                                 &
                                         this%dxdydV%data3d(i,j,k),this%dzdxdV%data3d(i,j,k),this%dydzdV%data3d(i,j,k),                    &
                                         this%cxyx%center(i,j,k),this%cxzx%center(i,j,k),this%cyxy%center(i,j,k),this%czxz%center(i,j,k), &
                                         0.5*(Txx(i-1,j,k)+Txx(i,j,k)),0.5*(Txx(i+1,j,k)+Txx(i,j,k)),             &
                                         0.5*(Txy(i,j-1,k)+Txy(i,j,k)),0.5*(Txy(i,j+1,k)+Txy(i,j,k)),             &
                                         0.5*(Txz(i,j,k-1)+Txz(i,j,k)),0.5*(Txz(i,j,k+1)+Txz(i,j,k)),             &
                                         Tyx(i,j,k),Tzx(i,j,k),Tyy(i,j,k),Tzz(i,j,k))

             ! y component of tensor divergence
             divTy(i,j,k) = Divergence3D(this%dAxdydz(i,j,k,1),this%dAxdydz(i,j,k,2),                                  &
                                         this%dAydzdx(i,j,k,1),this%dAydzdx(i,j,k,2),                                  &
                                         this%dAzdxdy(i,j,k,1),this%dAzdxdy(i,j,k,2),                                  &
                                         this%dxdydV%data3d(i,j,k),this%dzdxdV%data3d(i,j,k),this%dydzdV%data3d(i,j,k),                     &
                                        -this%cxyx%center(i,j,k),this%cyzy%center(i,j,k),-this%cyxy%center(i,j,k),this%czyz%center(i,j,k), &
                                         0.5*(Tyx(i-1,j,k)+Tyx(i,j,k)),0.5*(Tyx(i+1,j,k)+Tyx(i,j,k)),              &
                                         0.5*(Tyy(i,j-1,k)+Tyy(i,j,k)),0.5*(Tyy(i,j+1,k)+Tyy(i,j,k)),              &
                                         0.5*(Tyz(i,j,k-1)+Tyz(i,j,k)),0.5*(Tyz(i,j,k+1)+Tyz(i,j,k)),              &
                                         Txx(i,j,k),Tzy(i,j,k),Txy(i,j,k),Tzz(i,j,k))
             ! z component of tensor divergence
             divTz(i,j,k) = Divergence3D(this%dAxdydz(i,j,k,1),this%dAxdydz(i,j,k,2),                     &
                                         this%dAydzdx(i,j,k,1),this%dAydzdx(i,j,k,2),                     &
                                         this%dAzdxdy(i,j,k,1),this%dAzdxdy(i,j,k,2),                     &
                                         this%dxdydV%data3d(i,j,k),this%dzdxdV%data3d(i,j,k),this%dydzdV%data3d(i,j,k),        &
                                         this%czyz%center(i,j,k),-this%cxzx%center(i,j,k),-this%czxz%center(i,j,k),this%cyzy%center(i,j,k), &
                                         0.5*(Tzx(i-1,j,k)+Tzx(i,j,k)),0.5*(Tzx(i+1,j,k)+Tzx(i,j,k)), &
                                         0.5*(Tzy(i,j-1,k)+Tzy(i,j,k)),0.5*(Tzy(i,j+1,k)+Tzy(i,j,k)), &
                                         0.5*(Tzz(i,j,k-1)+Tzz(i,j,k)),0.5*(Tzz(i,j,k+1)+Tzz(i,j,k)), &
                                         Tyz(i,j,k),Txx(i,j,k),Txz(i,j,k),Tyy(i,j,k))
          END DO
       END DO
    END DO
  END SUBROUTINE TensorDivergence3D
!
!   TODO: Highly unsure whether this is correct....
!  ! the elemental workhorse: basic function for computing 2D/3D vector or tensor divergences
!  ! works with planar geometry as well (czxz = 0)
!  ! input: area and volume elements (multiplied and devided by dx or dy,
!  !        commutator coefficients, tensor components
!  ! output: vector divergence (scalar) or x-component of the tensor divergence
!  !         call this function with different input to obtain other components
  ELEMENTAL FUNCTION Divergence3D(dAxdydzWest,dAxdydzEast,dAydxdzSouth,dAydxdzNorth,dAzdxdyBottom,dAzdxdyTop, &
                                  dxdydV,dxdzdV,dydzdV,cxyx,cxzx,cyxy,czxz, &
                                  TxxWest,TxxEast,TxySouth,TxyNorth,TxzBottom,TxzTop, &
                                  TyxCent,TzxCent,TyyCent,TzzCent) RESULT(div)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    REAL,INTENT(IN) :: dAxdydzWest,dAxdydzEast, &       ! surface elements
                       dAydxdzSouth,dAydxdzNorth, &     !   dAx/dy, dAy/dx
                       dAzdxdyBottom,dAzdxdyTop, &
                       dxdydV,dxdzdV,dydzdV, &          ! dx/dV and dy/dV
                       cxyx,cyxy,czxz,cxzx, &           ! commutator coeffs
                       TxxEast,TxxWest, &               ! tensor components
                       TxyNorth,TxySouth, &             !   on cell faces
                       TxzBottom,TxzTop, &
                       TyxCent,TyyCent,TzzCent,TzxCent  !   central

                 !this rules are from fosite2D and will not work for 3D...maybe
                 !useful as a debugging orientation

                       ! to compute the y-component of the tensor divergence,
                       ! one has to modify the input according to
                       !   Txx   <->   Tyx
                       !   Txy   <->   Tyy
                       !   cxyx   ->   -cxyx
                       !   cyxy   ->   -cyxy
                       !   czxz   ->    czyz
                       ! to compute the z-component of the tensor divergence,
                       ! one has to modify the input according to
                       !   Txx    ->   Tzx
                       !   Txy    ->   Tzy
                       !   Tyx    ->   Tyz
                       !   Tyy    ->   0
                       !   Tzz    ->  -Txz
                       !   cxyx   ->   czyz
                       !   cyxy   ->   0
    !------------------------------------------------------------------------!
    REAL            :: div
    !------------------------------------------------------------------------!
    div = dydzdV*(dAxdydzEast*TxxEast-dAxdydzWest*TxxWest) &
        + dxdzdV*(dAydxdzNorth*TxyNorth-dAydxdzSouth*TxySouth) &
        + dxdydV*(dAzdxdyTop*TxzTop-dAzdxdyBottom*TxzBottom) &
        + cxyx*TyxCent + cxzx*TzxCent - cyxy*TyyCent - czxz*TzzCent
  END FUNCTION Divergence3D



  SUBROUTINE Finalize(this)
    IMPLICIT NONE
    !------------------------------------------------------------------------!
    CLASS(mesh_midpoint),INTENT(INOUT) :: this
    !------------------------------------------------------------------------!
    DEALLOCATE(this%dAx,this%dAy,this%dAz,this%dAxdydz,this%dAydzdx,this%dAzdxdy)
    CALL this%Finalize_base()
  END SUBROUTINE Finalize

END MODULE mesh_midpoint_mod
