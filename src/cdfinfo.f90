PROGRAM cdfinfo
  !!======================================================================
  !!                     ***  PROGRAM  cdfinfo  ***
  !!=====================================================================
  !!  ** Purpose : Give very basic informations for Netcdf File
  !!
  !!  ** Method  : to be improved
  !!
  !! History : 2.1  : 09/2010  : J.M. Molines : Original code
  !!           3.0  : 01/2011  : J.M. Molines : Doctor norm + Lic.
  !!         : 4.0  : 03/2017  : J.M. Molines  
  !!----------------------------------------------------------------------
  USE cdfio 
  USE modcdfnames
  !!----------------------------------------------------------------------
  !! CDFTOOLS_4.0 , MEOM 2017 
  !! $Id$
  !! Copyright (c) 2017, J.-M. Molines 
  !! Software governed by the CeCILL licence (Licence/CDFTOOLSCeCILL.txt)
  !! @class file_informations
  !!----------------------------------------------------------------------
  IMPLICIT NONE

  INTEGER(KIND=4)                               :: jvar, jarg               ! dummy loop index
  INTEGER(KIND=4)                               :: ierr                     ! working integer
  INTEGER(KIND=4)                               :: idep, idep_max           ! possible depth index, maximum
  INTEGER(KIND=4)                               :: narg, iargc, ijarg       ! 
  INTEGER(KIND=4)                               :: npiglo, npjglo, npk ,npt ! size of the domain
  INTEGER(KIND=4)                               :: nvars                    ! Number of variables in a file
  INTEGER(KIND=4)                               :: npoints                  ! Number of points with VALUE
  INTEGER(KIND=4), DIMENSION(1)                 :: ikloc                    ! used for MINLOC

  REAL(KIND=4)                                  :: zdep                     ! depth to look for
  REAL(KIND=4)                                  :: zval                     ! value to lookfor
  REAL(KIND=4), DIMENSION(:),       ALLOCATABLE :: zdept                    ! depth array
  REAL(KIND=4), DIMENSION(:,:),     ALLOCATABLE :: zv2d                     ! 2D working array

  CHARACTER(LEN=256)                            :: cf_in                    ! file name
  CHARACTER(LEN=256)                            :: cv_dep                   ! depth name
  CHARACTER(LEN=256)                            :: cv_var                   ! depth name
  CHARACTER(LEN=256)                            :: cldum                    ! dummy input variable
  CHARACTER(LEN=256), DIMENSION(:), ALLOCATABLE :: cv_names                 ! array of var name
  CHARACTER(LEN=256), DIMENSION(:), ALLOCATABLE :: clv_dep                  ! possible choices for dep dimension

  TYPE(variable), DIMENSION(:),     ALLOCATABLE :: stypvar                  ! variable attributes

  LOGICAL                                       :: ldep  =.FALSE.           ! flag for depth control
  LOGICAL                                       :: lval  =.FALSE.           ! flag for value control
  !!----------------------------------------------------------------------
  CALL ReadCdfNames()

  narg= iargc()

  IF ( narg == 0 ) THEN
     PRINT *,' usage : cdfinfo -f MODEL-file [-dep dep] [-val VAR-val] [-in VAR-name]'
     PRINT *,'      '
     PRINT *,'     PURPOSE :'
     PRINT *,'        Gives very basic information about the file given in arguments.'
     PRINT *,'      '
     PRINT *,'     ARGUMENTS :'
     PRINT *,'        model output file in netcdf.' 
     PRINT *,'      '
     PRINT *,'     OPTIONS :'
     PRINT *,'        [-dep depth ] : return the nearest k index corresponding to depth '
     PRINT *,'        [-val VAR-val ] : return the number of points with VAR-val in a '
     PRINT *,'              VAR-name variable.'
     PRINT *,'        [-in VAR-name ] : name of the variable for value check.'
     PRINT *,'      '
     PRINT *,'     OUTPUT : '
     PRINT *,'        On standard ouput, gives the size of the domain, the depth '
     PRINT *,'        dimension name, the number of variables.'
     PRINT *,'      '
     STOP 
  ENDIF

  ijarg=1
  cv_var='none'
  DO WHILE ( ijarg <= narg ) 
     CALL getarg(ijarg, cldum) ; ijarg=ijarg+1
     SELECT CASE ( cldum )
     CASE ( '-f'   ) ; CALL getarg (ijarg, cf_in) ;  ijarg=ijarg+1
        ! options
     CASE ( '-dep' ) ; CALL getarg (ijarg, cldum) ;  ijarg=ijarg+1 ; READ(cldum,*) zdep ;  ldep =.TRUE.
     CASE ( '-val' ) ; CALL getarg (ijarg, cldum) ;  ijarg=ijarg+1 ; READ(cldum,*) zval ;  lval =.TRUE.
     CASE ( '-in'  ) ; CALL getarg (ijarg, cv_var);  ijarg=ijarg+1 
     CASE DEFAULT   ; PRINT *, 'ERROR : ',TRIM(cldum),' : unknown option.' ; STOP 99
     END SELECT
  ENDDO

  IF ( chkfile(cf_in) ) STOP 99 ! missing file

  npiglo = getdim (cf_in,cn_x)
  npjglo = getdim (cf_in,cn_y)

  ! looking for npk among various possible name
  idep_max=8
  ALLOCATE ( clv_dep(idep_max) )
  clv_dep(:) = (/cn_z,'z','sigma','nav_lev','levels','ncatice','icbcla','icbsect'/)
  idep=1  ; ierr=1000
  DO WHILE ( ierr /= 0 .AND. idep <= idep_max )
     npk  = getdim (cf_in, clv_dep(idep), cdtrue=cv_dep, kstatus=ierr)
     idep = idep + 1
  ENDDO

  IF ( ierr /= 0 ) THEN  ! none of the dim name was found
     PRINT *,' assume file with no depth'
     npk=0
  ENDIF

  npt    = getdim (cf_in,cn_t)

  PRINT *, 'npiglo =', npiglo
  PRINT *, 'npjglo =', npjglo
  PRINT *, 'npk    =', npk
  PRINT *, 'npt    =', npt

  PRINT *,' Depth dimension name is ', TRIM(cv_dep)

  nvars = getnvar(cf_in)
  PRINT *,' nvars =', nvars

  ALLOCATE (cv_names(nvars)  )
  ALLOCATE (stypvar(nvars)  )

  ! get list of variable names 
  cv_names(:)=getvarname(cf_in, nvars, stypvar)

  DO jvar = 1, nvars
     PRINT *, 'variable# ',jvar,' is : ',TRIM(cv_names(jvar))
  END DO

  IF ( ldep ) THEN
     ALLOCATE(zdept(npk) )
     zdept = getdimvar (cf_in,  npk)
     ikloc= MINLOC( ABS(zdept - zdep) )
     PRINT * ,' NEAREST_K ',ikloc(1)
  ENDIF
  
  IF (lval ) THEN
     ALLOCATE( zv2d(npiglo, npjglo ) )
     zv2d=getvar(cf_in, cv_var, 1, npiglo, npjglo)
     WHERE (zv2d /= zval ) 
       zv2d = 0.
     ELSEWHERE
       zv2d = 1.
     END WHERE
     npoints = SUM(zv2d )
     PRINT *,' VAR  ', TRIM(cv_var),'  : value  ', zval,'  : ', npoints
  ENDIF


END PROGRAM cdfinfo
