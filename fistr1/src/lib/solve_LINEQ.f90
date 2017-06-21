!-------------------------------------------------------------------------------
! Copyright (c) 2016 The University of Tokyo
! This software is released under the MIT License, see LICENSE.txt
!-------------------------------------------------------------------------------
!> \brief This program is a HECMW interface to a set of linear iterative and direct
!! solvers. The interface may be called from within a HECMW application, with
!! an appropriate choice of TYPE (iterative, direct), and METHOD (depending
!! on the iterative solver used).
module m_solve_LINEQ
   implicit none

   private
   public :: solve_LINEQ

   contains

   SUBROUTINE solve_LINEQ(hecMESH,hecMAT,imsg)
      USE hecmw
      USE hecmw_solver_11
      USE hecmw_solver_22
      USE hecmw_solver_33
      USE hecmw_solver_44
      USE hecmw_solver_66
      USE hecmw_solver_direct
      USE hecmw_solver_direct_parallel
      USE hecmw_solver_direct_MUMPS
      USE hecmw_solver_direct_clusterMKL
      type (hecmwST_local_mesh) :: hecMESH
      type (hecmwST_matrix    ) :: hecMAT
      type (hecmwST_matrix),allocatable :: hecMAT2

      INTEGER(kind=kint) imsg, i, myrank
      real(kind=kreal) :: resid
!C
      SELECT CASE(hecMAT%Iarray(99))
!C
!* Call Iterative Solver
      CASE (1)
!C
        SELECT CASE(hecMESH%n_dof)
        CASE(1)
!          WRITE(*,*) "Calling 1x1 Iterative Solver..."
          CALL hecmw_solve_11(hecMESH,hecMAT)
        CASE(2)
!          WRITE(*,*) "Calling 2x2 Iterative Solver..."
          allocate(hecMAT2)
          call hecmw_nullify_matrix( hecMAT2 )
          call hecmw_cmat_init(hecMAT2%cmat)

          allocate(hecMAT2%B(3*hecMAT%NP))
          allocate(hecMAT2%X(3*hecMAT%NP))
          allocate(hecMAT2%D(9*hecMAT%NP))
          allocate(hecMAT2%AL(9*hecMAT%NPL))
          allocate(hecMAT2%AU(9*hecMAT%NPU))
          hecMAT2%indexL => hecMAT%indexL
          hecMAT2%indexU => hecMAT%indexU
          hecMAT2%itemL  => hecMAT%itemL
          hecMAT2%itemU  => hecMAT%itemU
          hecMAT2%N    = hecMAT%N
          hecMAT2%NP   = hecMAT%NP
          hecMAT2%NPL  = hecMAT%NPL
          hecMAT2%NPU  = hecMAT%NPU
          hecMAT2%NDOF = 3
          hecMAT2%Iarray = hecMAT%Iarray
          hecMAT2%Rarray = hecMAT%Rarray
          
          do i = 1, hecMAT%NP
            hecMAT2%D(9*i-8) = hecMAT%D(4*i-3)
            hecMAT2%D(9*i-7) = hecMAT%D(4*i-2)
            hecMAT2%D(9*i-6) = 0
            hecMAT2%D(9*i-5) = hecMAT%D(4*i-1)
            hecMAT2%D(9*i-4) = hecMAT%D(4*i-0)
            hecMAT2%D(9*i-3) = 0
            hecMAT2%D(9*i-2) = 0
            hecMAT2%D(9*i-1) = 0
            hecMAT2%D(9*i-0) = 1
            hecMAT2%B(3*i-2) = hecMAT%B(2*i-1)
            hecMAT2%B(3*i-1) = hecMAT%B(2*i)
            hecMAT2%B(3*i-0) = 0
            hecMAT2%X(3*i-2) = hecMAT%X(2*i-1)
            hecMAT2%X(3*i-1) = hecMAT%X(2*i)
            hecMAT2%X(3*i-0) = 0
          end do 
          do i = 1, hecMAT%NPL
            hecMAT2%AL(9*i-8) = hecMAT%AL(4*i-3)
            hecMAT2%AL(9*i-7) = hecMAT%AL(4*i-2)
            hecMAT2%AL(9*i-6) = 0
            hecMAT2%AL(9*i-5) = hecMAT%AL(4*i-1)
            hecMAT2%AL(9*i-4) = hecMAT%AL(4*i-0)
            hecMAT2%AL(9*i-3) = 0
            hecMAT2%AL(9*i-2) = 0
            hecMAT2%AL(9*i-1) = 0
            hecMAT2%AL(9*i-0) = 0
          end do 
          do i = 1, hecMAT%NPU
            hecMAT2%AU(9*i-8) = hecMAT%AU(4*i-3)
            hecMAT2%AU(9*i-7) = hecMAT%AU(4*i-2)
            hecMAT2%AU(9*i-6) = 0
            hecMAT2%AU(9*i-5) = hecMAT%AU(4*i-1)
            hecMAT2%AU(9*i-4) = hecMAT%AU(4*i-0)
            hecMAT2%AU(9*i-3) = 0
            hecMAT2%AU(9*i-2) = 0
            hecMAT2%AU(9*i-1) = 0
            hecMAT2%AU(9*i-0) = 0
          end do 

          call hecmw_solve_33 (hecMESH, hecMAT2)
          do i = 1, hecMAT%NP
            hecMAT%X(2*i-1) = hecMAT2%X(3*i-2)
            hecMAT%X(2*i-0) = hecMAT2%X(3*i-1)
          end do 

          hecMAT%Iarray = hecMAT2%Iarray
          hecMAT%Rarray = hecMAT2%Rarray
          deallocate(hecMAT2%B)
          deallocate(hecMAT2%D)
          deallocate(hecMAT2%X)
          deallocate(hecMAT2%AL)
          deallocate(hecMAT2%AU)
          deallocate(hecMAT2)


!          CALL hecmw_solve_22(hecMESH,hecMAT)
        CASE(3)
!          WRITE(*,*) "Calling 3x3 Iterative Solver..."
          CALL hecmw_solve_33(hecMESH,hecMAT)
        CASE(4)
!          WRITE(*,*) "Calling 4x4 Iterative Solver..."
          CALL hecmw_solve_44(hecMESH,hecMAT)
        CASE(5)
          !CALL hecmw_solve_mm(hecMESH,hecMAT)
!          WRITE(*,*) "FATAL: Solve_mm not yet available..."
          call hecmw_abort( hecmw_comm_get_comm() )
        CASE(6)
!          WRITE(*,*) "Calling 6x6 Iterative Solver..."
          CALL hecmw_solve_66(hecMESH,hecMAT)
        CASE(7:)
          !CALL hecmw_solve_mm(hecMESH,hecMAT)
!          WRITE(*,*) "FATAL: Solve_mm not yet available..."
          call hecmw_abort( hecmw_comm_get_comm() )
        END SELECT
!C
!* Call Direct Solver
      CASE(2:)
!C
!* Please note the following:
!* Flag to activate symbolic factorization: 1(yes) 0(no)  hecMESH%Iarray(98)
!* Flag to activate numeric  factorization: 1(yes) 0(no)  hecMESH%Iarray(97)

        if (hecMAT%Iarray(97) .gt. 1) hecMAT%Iarray(97)=1

        if (hecMAT%Iarray(2) .eq. 104) then
          call hecmw_solve_direct_MUMPS(hecMESH, hecMAT)
        elseif (hecMAT%Iarray(2) .eq. 105) then
          call hecmw_solve_direct_ClusterMKL(hecMESH, hecMAT)
        else
          IF(hecMESH%PETOT.GT.1) THEN
            CALL hecmw_solve_direct_parallel(hecMESH,hecMAT,imsg)
          ELSE
            CALL hecmw_solve_direct(hecMESH,hecMAT,imsg)
          ENDIF
!!!       hecMAT%X = hecMAT%B -- leading stack overflow (intel9)
          do i=1,hecMAT%NP*hecMESH%n_dof
              hecMAT%X(i) = hecMAT%B(i)
          end do
        endif

        SELECT CASE(hecMESH%n_dof)
        CASE(1)
          resid=hecmw_rel_resid_L2_11(hecMESH,hecMAT)
        CASE(2)
          resid=hecmw_rel_resid_L2_22(hecMESH,hecMAT)
        CASE(3)
          resid=hecmw_rel_resid_L2_33(hecMESH,hecMAT)
        CASE(4:)
          resid=hecmw_rel_resid_L2_44(hecMESH,hecMAT)
        END SELECT
        myrank=hecmw_comm_get_rank()
        if (myrank==0) then
          write(*,"(a,1pe12.5)")'### Relative residual =', resid
          if( resid >= 1.0d-8) then
            write(*,"(a)")'### Relative residual exceeded 1.0d-8---Direct Solver### '
!            stop
          endif
        endif
!C
      END SELECT
!C
      RETURN

   end subroutine solve_LINEQ

end module m_solve_LINEQ
