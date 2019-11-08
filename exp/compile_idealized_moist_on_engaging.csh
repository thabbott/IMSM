#!/bin/csh -f

# Check that repository is clean
bash preBuild
if ($status != 0) then
    exit
endif

unalias *
set echo
#--------------------------------------------------------------------------------------------------------
set platform  = engaging.intel                           # A unique identifier for your platform
set template  = $cwd/../bin/mkmf.template.$platform  # path to template for your platform
set mkmf      = $cwd/../bin/mkmf                     # path to executable mkmf
set sourcedir = $cwd/../src                          # path to directory containing model source code
set pathnames = $cwd/../input/path_names             # path to file containing list of source paths
set ppdir     = $cwd/../postprocessing               # path to directory containing the tool for combining distributed diagnostic output files
#--------------------------------------------------------------------------------------------------------
set execdir = $cwd/exec.$platform  # where code is compiled and executable is created
set executable = $execdir/idealized_moist.x

source /etc/profile.d/modules.csh
module load engaging/intel/2013.1.046
module load engaging/hdf5
module load engaging/zlib/1.2.8
module list

#--------------------------------------------------------------------------------------------------------
# compile combine tool
cd $ppdir
icc -O -c -I/home/thabbott/local/netcdf/4.5.0/include mppnccombine.c
if ( $status != 0 ) exit 1
icc -O -o mppnccombine.x -L/home/thabbott/local/netcdf/4.5.0/lib -lnetcdf  mppnccombine.o
if ( $status != 0 ) exit 1
#--------------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------------
# setup directory structure
if ( ! -d $execdir ) mkdir -p $execdir
cd $execdir
#--------------------------------------------------------------------------------------------------------

# execute mkmf to create makefile
set cppDefs = "-Duse_libMPI -Duse_netCDF -Duse_LARGEFILE -DINTERNAL_FILE_NML -DOVERLOAD_C8"
$mkmf -a $sourcedir -t $template -p $executable:t -c "$cppDefs" $pathnames $sourcedir/shared/include $sourcedir/shared/mpp/include
if ( $status != 0 ) then
   unset echo
   echo "ERROR: mkmf failed for idealized_moist model"
   exit 1
endif

# --- execute make ---
make $executable:t
if ( $status != 0 ) then
   unset echo
   echo "ERROR: make failed for idealized_moist model"
   exit 1
endif

unset echo
echo "NOTE: make successful for idealized_moist model"

bash postBuild $executable
