!-------------------------------------------------------------------------------
! add a channel mask to an existing mask function
! e.g. there is an insect already in mask and we now put
! channel walls around it.
! the channel walls have the color "0" which helps excluding them 
! for example when computing the integral forces
!-------------------------------------------------------------------------------
subroutine add_channel()
  use mpi
  use fsi_vars
  implicit none
  integer :: ix,iy,iz
  real (kind=pr) :: thick_wall, x,y, z, pos_wall, usponge, H_eff, z_chan
  
  ! Wall parameters
  thick_wall = 0.2d0
  pos_wall = 0.3d0
  
  
  ! loop over the physical space
  do ix = ra(1), rb(1)
    do iy = ra(2), rb(2)
       do iz = ra(3), rb(3)
          !----------------
          select case (iChannel)
          case ("xz")
            ! Floor - xz solid wall between y_wall-thick_wall and y_wall
            y = dble(iy)*dy
            if ( (y>=pos_wall-thick_wall) .and. (y<=pos_wall) ) then
              mask(ix,iy,iz) = 1.d0
              us(ix,iy,iz,:) = 0.d0  
              ! external boxes have color 0 (important for forces)
              mask_color(ix,iy,iz) = 0
            endif

          case ("xy")
            ! Floor - xy solid wall between z_wall-thick_wall and z_wall
            z = dble(iz)*dz
            if ( (z>=pos_wall-thick_wall) .and. (z<=pos_wall) ) then
              mask(ix,iy,iz) = 1.d0
              us(ix,iy,iz,:) = 0.d0  
              ! external boxes have color 0 (important for forces)
              mask_color(ix,iy,iz) = 0
            endif
            
          case ("turek")
            ! Turek walls: 
            thick_wall = 0.2577143d0
            usponge = 0.5060014d0
            H_eff = zl-2.d0*thick_wall
                      
            z = dble(iz)*dz
            x = dble(ix)*dx
            z_chan = z-thick_Wall
            
            !-- channel walls
            if ((z<=thick_Wall).or.(z>=zl-thick_Wall)) then
              mask(ix,iy,iz) = 1.d0
              mask_color(ix,iy,iz) = 0
              us(ix,iy,iz,:) = 0.d0  
            endif
              
            if ((x<=usponge).and.(z>=thick_Wall).and.(z<=zl-thick_Wall)) then
              !-- velocity sponge
              mask(ix,iy,iz) = 1.d0
              mask_color(ix,iy,iz) = 0
              us(ix,iy,iz,1) = 1.5*z_chan*(H_eff-z_chan)/((0.5*H_eff)**2)
              us(ix,iy,iz,2:3) = 0.d0  
            endif
            
          case default
            write (*,*) "add_channel()::iChannel is not a known value"
            stop
          end select
          !----------------
       enddo
    enddo
  enddo
 
end subroutine add_channel
