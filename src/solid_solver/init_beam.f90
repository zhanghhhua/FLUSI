subroutine init_beams ( beams )
  !---------------------------------------------------
  ! initializes an array of beams. the initial state is always
  ! straight lines, possible oriented with different angles, at rest.
  !---------------------------------------------------
  implicit none
  integer :: n, i
  type(solid), dimension (1:nBeams), intent (out) :: beams  
  real (kind=pr) :: alpha, alpha_t, alpha_tt
  ! LeadingEdge: x, y, vx, vy, ax, ay (Array)  
  real (kind=pr), dimension(1:6) :: LeadingEdge
  character(len=strlen) :: fname
  character(len=1)  :: beamstr
  
  if (mpirank==0) then
    write (*,'("*** initializing ",i1," beams")')  nBeams
    write (*,'("--- Beam width (2*t_beam) covers ",(f4.1)," points")') &
    2.0*t_beam/max(dy,dx)
  endif
 
  call lapack_unit_test()
  
  !-------------------------------------------
  ! allocate beam storage for each beam
  !-------------------------------------------
  do i = 1, nBeams
    allocate ( beams(i)%x(0:ns-1) )
    allocate ( beams(i)%y(0:ns-1) )
    allocate ( beams(i)%vx(0:ns-1) )
    allocate ( beams(i)%vy(0:ns-1) )
    allocate ( beams(i)%ax(0:ns-1) )
    allocate ( beams(i)%ay(0:ns-1) )
    allocate ( beams(i)%theta(0:ns-1) )
    allocate ( beams(i)%theta_dot(0:ns-1) )
    allocate ( beams(i)%pressure_old(0:ns-1) )
    allocate ( beams(i)%pressure_new(0:ns-1) )
    allocate ( beams(i)%tau_old(0:ns-1) )
    allocate ( beams(i)%tau_new(0:ns-1) )    
    allocate ( beams(i)%beam_oldold(0:ns-1,1:6) )    
    ! overwrite beam files if not retaking a backup
    if ( index(inicond,'backup::') == 0 ) then
      write (beamstr,'(i1)') i
      open  (14, file = 'beam_data'//beamstr//'.t', status = 'replace')
      close (14)
      open  (14, file = 'mouvement'//beamstr//'.t', status = 'replace')
      close (14)      
    endif
  enddo 
  
  !---------------------------------------------
  ! define adjustable parameters for each beam 
  ! this is position and motion protocoll
  !--------------------------------------------
  beams(1)%x0 = 0.d0 ! always zero, translation and rotation is handled elsewhere
  beams(1)%y0 = 0.d0 
  beams(1)%AngleBeam = AngleBeam
  beams(1)%phase = 0.d0  
  
  !---------------------------------------------
  ! loop over beams and initialize them
  !---------------------------------------------
  do i = 1, nBeams
    ! fetch leading edge position 
    call mouvement(0.d0, alpha, alpha_t, alpha_tt, LeadingEdge, beams(i) )
    ! initialize as zero
    beams(i)%x = 0.d0
    beams(i)%y = 0.d0
    beams(i)%vx = 0.d0
    beams(i)%vy = 0.d0
    beams(i)%ax = 0.d0
    beams(i)%ay = 0.d0
    beams(i)%theta = 0.d0
    beams(i)%theta_dot = 0.d0
    beams(i)%pressure_old = 0.d0
    beams(i)%pressure_new = 0.d0
    beams(i)%tau_old = 0.d0
    beams(i)%tau_new = 0.d0   
    beams(i)%beam_oldold = 0.d0
    beams(i)%Inertial_Force = 0.d0
    ! this is used for unst correction computation:
    beams(i)%drag_unst_new = 0.d0
    beams(i)%drag_unst_old = 0.d0
    beams(i)%lift_unst_new = 0.d0
    beams(i)%lift_unst_old = 0.d0
    beams(i)%UnsteadyCorrectionsReady = .false.
    beams(i)%StartupStep = .true.
    beams(i)%dt_old = 0.d0
    
    ! remember that what follows is described in relative coordinates 
    do n = 0, ns-1 
      beams(i)%x(n) = LeadingEdge(1) + dble(n)*ds
      beams(i)%y(n) = LeadingEdge(2)
      beams(i)%vx(n)= 0.d0
      beams(i)%vy(n)= 0.d0
      beams(i)%ax(n)= 0.d0
      beams(i)%ay(n)= 0.d0
    enddo
     ! to take static angle into account
    call integrate_position (0.d0, beams(i))
  enddo
  
  
  !-------------------------------------------
  ! If we resume a backup, read from file (all ranks do that)
  !-------------------------------------------
  if ( index(inicond,'backup::') /= 0 ) then
    fname = inicond(index(inicond,'::')+2:index(inicond,'.'))//'fsi_bckp'
    call read_solid_backup( beams, trim(adjustl(fname)) )
  endif
end subroutine init_beams
