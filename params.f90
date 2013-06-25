! Wrapper to read parameters from an ini file for fsi.  Also reads
! parameters which are set in the vars module.
subroutine get_params(paramsfile) 
  use vars

  character (len=80) :: paramsfile  ! The file we read the PARAMS from
  integer :: i  
  character PARAMS(nlines)*256 ! this array will contain the ascii-params file

  ! Read the paramsfile and put the length i and the text in PARAMS
  call read_params_file(PARAMS,i,paramsfile)

  ! Get parameter values from PARAMS
  call get_params_common(PARAMS,i)

  select case(method(1:3))
     case("fsi") 
        ! Get fsi-specific parameter values from PARAMS
        call get_params_fsi(PARAMS,i)
     case("mhd") 
        ! Get mhd-specific parameter values from PARAMS
        call get_params_mhd(PARAMS,i)
  case default
     if (mpirank == 0) then
        write(*,*) "Error! Unkonwn method in get_params"
        stop
     end if
  end select
end subroutine get_params


! Read the file paramsfile, count the lines (output in i) and put the
! text in PARAMS.
subroutine read_params_file(PARAMS,i,paramsfile)
  use mpi_header
  use vars
  implicit none
  
  integer, intent(out) :: i
  integer :: io_error
 ! this array will contain the ascii-params file
  character, intent(inout) :: PARAMS(nlines)*256
  character (len=80) :: paramsfile ! this is the file we read the PARAMS from
 
  ! Read in the params file (root only)
  io_error=0
  if (mpirank==0) then
     write (*,*) "*************************************************"
     write (*,'(A,i3)') " *** info: reading params from "//trim(paramsfile)//" rank=", mpirank
     write (*,*) "*************************************************"
     i = 1
     open(unit=14,file=paramsfile,action='read',status='old')    
     do while ((io_error==0).and.(i<=nlines))
        read (14,'(A)',iostat=io_error) PARAMS(i)  
        i = i+1
     enddo
     close (14)
     i = i-1 ! counted one too far
  endif

end subroutine read_params_file


! Read individual parameter values from the PARAMS string for the vars
! module.
subroutine get_params_common(PARAMS,i)
  use mpi_header
  use vars
  implicit none

  integer,intent(in) :: i
  character,intent(in) :: PARAMS(nlines)*256 ! Contains the ascii-params file

  ! Resolution section
  call GetValue_Int(PARAMS,i,"Resolution","nx",nx, 4)
  call GetValue_Int(PARAMS,i,"Resolution","ny",ny, 4)
  call GetValue_Int(PARAMS,i,"Resolution","nz",nz, 4)

  ! Time section
  call GetValue_Int(PARAMS,i,"Time","nt",nt, 9999999)
  ! This is the default value. ifort complains when just putting it in the call
  iTimeMethodFluid = "AB2" 
  call GetValue_String(PARAMS,i,"Time","iTimeMethodFluid", iTimeMethodFluid,&
       iTimeMethodFluid)  
  call GetValue_Real(PARAMS,i,"Time","Tmax",Tmax, 1.d9)
  call GetValue_Real(PARAMS,i,"Time","CFL",cfl, 0.1d0)
  call GetValue_Real(PARAMS,i,"Time","dt_fixed",dt_fixed, 0.d0)

  ! Reynolds number section:
  call GetValue_Real(PARAMS,i,"ReynoldsNumber","nu",nu, 1.d-2)  
  inicond = "none"

  ! Initial conditions section
  call GetValue_String(PARAMS,i,"InitialCondition","inicond",inicond, inicond)

  ! Dealasing section
  call GetValue_Int(PARAMS,i,"Dealiasing","iDealias",iDealias, 1)

  ! Penalization section
  call GetValue_Int(PARAMS,i,"Penalization","iPenalization",iPenalization, 0)
  call GetValue_Int(PARAMS,i,"Penalization","iMoving",iMoving, 0)
  imask="none"
  call GetValue_String(PARAMS,i,"Penalization","iMask",iMask, iMask)
  call GetValue_Real(PARAMS,i,"Penalization","eps",eps, 1.d-2)

  ! Geometry section
  call GetValue_Real(PARAMS,i,"Geometry","xl",xl, 1.d0)
  call GetValue_Real(PARAMS,i,"Geometry","yl",yl, 1.d0)
  call GetValue_Real(PARAMS,i,"Geometry","zl",zl, 1.d0)
  call GetValue_Real(PARAMS,i,"Geometry","Size",length, 0.d0)

  ! MeanFlow section
  call GetValue_Int(PARAMS,i,"MeanFlow","iMeanFlow",iMeanFlow, 3)  
  call GetValue_Real(PARAMS,i,"MeanFlow","ux",ux, 1.d0) 
  call GetValue_Real(PARAMS,i,"MeanFlow","uy",uy, 1.d0) 
  call GetValue_Real(PARAMS,i,"MeanFlow","uz",uz, 1.d0) 

  ! Saving section
  call GetValue_Int(PARAMS,i,"Saving","iDoBackup",iDoBackup, 1)
  call GetValue_Int(PARAMS,i,"Saving","iSaveVelocity",iSaveVelocity, 0) 
  call GetValue_Int(PARAMS,i,"Saving","iSavePress",iSavePress, 0)
  call GetValue_Int(PARAMS,i,"Saving","iSaveVorticity",iSaveVorticity, 1)  
  call GetValue_Int(PARAMS,i,"Saving","iSaveMask",iSaveMask, 0)
  call GetValue_Int(PARAMS,i,"Saving","iSaveSolidVelocity",iSaveSolidVelocity,0)
  call GetValue_Real(PARAMS,i,"Saving","tsave",tsave, 9.d9)
  call GetValue_int(PARAMS,i,"Saving","itdrag",itdrag, 99999)
  call GetValue_int(PARAMS,i,"Saving","iDrag",iDrag, 0)
  call GetValue_int(PARAMS,i,"Saving","iKinDiss",iKinDiss, 0)

  ! Set other parameters (all procs)
  pi=4.d0 *datan(1.d0)
  scalex=2.d0*pi/xl
  scaley=2.d0*pi/yl
  scalez=2.d0*pi/zl  
  dx=xl/dble(nx)
  dy=yl/dble(ny)
  dz=zl/dble (nz) 
  tstart=0.d0
end subroutine get_params_common


! Read individual parameter values from the PARAMS string for fsi.
subroutine get_params_fsi(PARAMS,i)
  use mpi_header
  use fsi_vars
  implicit none

  integer,intent(in) :: i
  character,intent(in) :: PARAMS(nlines)*256 ! Contains the ascii-params file

  ! FSIGeometry section
  call GetValue_Real(PARAMS,i,"FSIGeometry","x0",x0, 0.d0)
  call GetValue_Real(PARAMS,i,"FSIGeometry","y0",y0, 0.d0)
  call GetValue_Real(PARAMS,i,"FSIGeometry","z0",z0, 0.d0)

  if (mpirank==0) then
     write (*,*) "*************************************************"
     write (*,'(A,i3)') " *** DONE READING PARAMETERS"
     write (*,*) "*************************************************"
  endif
end subroutine get_params_fsi


! Read individual parameter values from the PARAMS string for fmhd
subroutine get_params_mhd(PARAMS,i)
  use mpi_header
  use mhd_vars
  implicit none

  integer,intent(in) :: i
  character,intent(in) :: PARAMS(nlines)*256 ! Contains the ascii-params file

  ! MHD section
  call GetValue_Real(PARAMS,i,"MHD","eta",eta,4.5d-2)

  ! MHDGeometry section
  call GetValue_Real(PARAMS,i,"MHDGeometry","b0",b0,4.5d0)
  call GetValue_Real(PARAMS,i,"MHDGeometry","bc",bc,3.88888888888d0)
  call GetValue_Real(PARAMS,i,"MHDGeometry","r1",r1,1.d0)
  call GetValue_Real(PARAMS,i,"MHDGeometry","r2",r2,1.0681415d0)
end subroutine get_params_mhd


! FIXME: document
subroutine GetValue_real (PARAMS, actual_lines, section, keyword, params_real, &
     defaultvalue)
  use vars
  use mpi_header
  implicit none
  character section*(*) ! What section do you look for? for example [Resolution]
  character keyword*(*)   ! what keyword do you look for? for example nx=128
  character (len=80)  value    ! returns the value
  character PARAMS(nlines)*256  ! this is the complete PARAMS.ini file
  real (kind=pr) :: params_real, defaultvalue 
  integer actual_lines
  integer mpicode

  ! Root rank fetches value from PARAMS.ini file (which is in PARAMS)
  if (mpirank==0) then
     call GetValue(PARAMS, actual_lines, section, keyword, value)
     if (value .ne. '') then
        read (value, *) params_real    
        write (value,'(g10.3)') params_real
        write (*,*) "read "//trim(section)//"::"//trim(keyword)//" = "//adjustl(trim(value))
     else
        write (value,'(g10.3)') defaultvalue
        write (*,*) "read "//trim(section)//"::"//trim(keyword)//" = "//adjustl(trim(value))//&
             " (THIS IS THE DEFAULT VALUE!)"
        params_real = defaultvalue
     endif
  endif
  
  ! And then broadcast
  call MPI_BCAST( params_real, 1, mpireal, 0, MPI_COMM_WORLD, mpicode ) 
end subroutine GetValue_real


! FIXME: document
subroutine GetValue_string (PARAMS, actual_lines, section, keyword, &
     params_string, defaultvalue)
  use vars
  use mpi_header
  implicit none
  
  character section*(*) ! what section do you look for? for example [Resolution]
  character keyword*(*)   ! what keyword do you look for? for example nx=128
  character (len=80)  value    ! returns the value
  character PARAMS(nlines)*256  ! this is the complete PARAMS.ini file
  character (len=80), intent (inout) :: params_string
  character (len=80), intent (inout) :: defaultvalue 
  integer actual_lines
  integer mpicode

  !------------------
  ! Root rank fetches value from PARAMS.ini file (which is in PARAMS)
  !------------------  
  if (mpirank==0) then
     call GetValue(PARAMS, actual_lines, section, keyword, value)
     if (value .ne. '') then
        params_string = value
        write (*,*) "read "//trim(section)//"::"//trim(keyword)//" = "//adjustl(trim(value))
     else
        write (*,*) "read "//trim(section)//"::"//trim(keyword)//" = "//adjustl(trim(value))//&
             " (THIS IS THE DEFAULT VALUE!)"
        params_string = defaultvalue
     endif
  endif

  ! And then broadcast
  call MPI_BCAST( params_string, 80, MPI_CHARACTER, 0, MPI_COMM_WORLD, mpicode) 
end subroutine GetValue_string


! Extracts a value from the PARAMS.ini file, which is in "section" and
! which is named "keyword"
subroutine GetValue (PARAMS, actual_lines, section, keyword, value)
  use vars
  use mpi_header
  implicit none

  character section*(*) ! What section do you look for? for example [Resolution]
  character keyword*(*)   ! what keyword do you look for? for example nx=128
  character value*(*)   ! returns the value
  character PARAMS(nlines)*256  ! this is the complete PARAMS.ini file
  integer actual_lines   ! how many lines did you actually read?  
  integer :: maxline = 256  ! how many characters per line?
  integer i, j,k
  logical foundsection

  foundsection = .false.
  value = ''

  !------------------------------------------------------------------
  do i=1, actual_lines     ! loop over the lines of PARAMS.ini file
     if ((PARAMS(i)(1:1).ne.'#').and.&
          (PARAMS(i)(1:1).ne.';').and.&
          (PARAMS(i)(1:1).ne.'!')) then   ! ignore commented lines compleetly


        if (PARAMS(i)(1:1) == '[') then   ! the first char would have to be '['
           do j = 2, maxline    ! then we look fot the corrresponding ']'
              if (PARAMS(i)(j:j) == ']') then  ! we found it
                 if (section == PARAMS(i)(2:j-1)) then ! is this the section we"re looking for?
                    foundsection = .true.   ! yes, it is
                    exit
                 endif
              endif
           enddo
        else      
           if (foundsection .eqv. .true.) then  ! yes we found the section, now we're looking for the keyword
              do j=1, maxline    ! scan the line
                 if (PARAMS(i)(j:j) == '=') then  ! found the '='
                    if (keyword == PARAMS(i)(1:j-1)) then ! is this the keyword you're looking for?
                       do k = j+1, maxline   ! everything behind the '=' and before ';' is the value
                          if (PARAMS(i)(k:k) == ';') then  ! found the delimiter
                             value = PARAMS(i)(j+1:k-1)  ! value is between '=', and ';'   
                             exit
                          endif
                       enddo
                       if ((value == '').and.(mpirank==0)) then
                          write (*,'(A)') "??? Though found the keyword, I'm unable to find value for variable --> "& 
                               //trim(keyword)//" <-- maybe missing delimiter (;)?"    
                       endif
                    endif
                 endif
              enddo
           endif
        endif

     endif
  enddo
end subroutine getvalue


! FIXME: document
subroutine GetValue_Int(PARAMS, actual_lines, section, keyword, params_int,&
     defaultvalue)
  use mpi_header
  use vars
  implicit none

  character section*(*) ! What section do you look for? for example [Resolution]
  character keyword*(*)   ! what keyword do you look for? for example nx=128
  character (len=80)  value    ! returns the value
  character PARAMS(nlines)*256  ! this is the complete PARAMS.ini file
  integer params_int, actual_lines, defaultvalue
  integer mpicode

  !------------------
  ! Root rank fetches value from PARAMS.ini file (which is in PARAMS)
  !------------------
  if (mpirank==0) then
     call GetValue(PARAMS, actual_lines, section, keyword, value)
     if (value .ne. '') then
        read (value, *) params_int
        write (value,'(i7)') params_int
        write (*,*) "read "//trim(section)//"::"//trim(keyword)//" = "//adjustl(trim(value))
     else
        write (value,'(i7)') defaultvalue
        write (*,*) "read "//trim(section)//"::"//trim(keyword)//" = "//adjustl(trim(value))//&
             " (THIS IS THE DEFAULT VALUE!)"
        params_int = defaultvalue
     endif
  endif

  ! And then broadcast
  call MPI_BCAST( params_int, 1, mpiinteger, 0, MPI_COMM_WORLD, mpicode )  
end subroutine GetValue_Int
