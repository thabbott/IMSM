#!/bin/csh -f
#Minimal runscript
set echo 
#--------------------------------------------------------------------------------------------------------
# define variables
set execid = mtdiag
set execdir = exec.engaging.intel
set execname = idealized_moist
set executable = ${execname}_${execid}
set exp = `basename $cwd`
set npes = 1                                   # Number of processors
set num_executions = 1                         # Number of times the model is run. Each run restarts from previous run.
set time_stamp = $cwd/../../bin/time_stamp.csh    # Path to timestamp.csh
set model_executable = $cwd/../../exp/$execdir/$executable  # Path to model executable
set mppnccombine = $cwd/../../postprocessing/mppnccombine.x    # The tool for combining distributed diagnostic output files
set workdir = /nfs/twcroninlab002/thabbott/IMSM/$executable/$exp  # Where model is run and model output is produced
#--------------------------------------------------------------------------------------------------------
source /etc/profile.d/modules.csh
module load engaging/intel/2013.1.046
module load engaging/hdf5
module load engaging/zlib/1.2.8
module list

set namelist   = $cwd/input.nml       # path to namelist file (contains all namelists)
set diagtable  = $cwd/diag_table      # path to diagnositics table (specifies fields and files for diagnostic output)
set fieldtable = $cwd/field_table     # path to field table (specifies tracers)
#--------------------------------------------------------------------------------------------------------

# setup directory structure
if ( -d $workdir ) then
  /bin/rm -rf $workdir/*
else
  mkdir -p $workdir
endif
cd $workdir
mkdir INPUT RESTART
#--------------------------------------------------------------------------------------------------------
# get input data and executable
cp $namelist   input.nml
cp $diagtable  diag_table
cp $fieldtable field_table
cp $model_executable .

set irun = 1
while ( $irun <= $num_executions )
#--------------------------------------------------------------------------------------------------------

# ru nthe model
setenv LD_LIBRARY_PATH /home/thabbott/local/netcdf-fortran/4.4.4/lib:/home/thabbott/local/netcdf/4.5.0/lib:$LD_LIBRARY_PATH
mpirun -n $npes ./$model_executable:t
if ($status != 0) then
  echo "Error in execution of $cwd/$model_executable:t"
  exit 1
endif
#--------------------------------------------------------------------------------------------------------
set date_name = `$time_stamp -bf digital`
foreach outfile ( *.out )
  mv $outfile $date_name.$outfile
end
#--------------------------------------------------------------------------------------------------------
# combine diagnostic files, then remove the uncombined files.
if ( $npes > 1 ) then
  foreach ncfile (`/bin/ls *.nc.0000`)
    $mppnccombine $ncfile:r
    if ($status == 0) then
      rm -f $ncfile:r.[0-9][0-9][0-9][0-9]
      mv $ncfile:r $date_name.$ncfile:r
    else
      echo "Error in execution of $mppnccombine while working on $ncfile:r"
      exit 1
    endif
  end
endif
#--------------------------------------------------------------------------------------------------------
# Prepare to run the model again
cd $workdir
/bin/rm INPUT/*.res   INPUT/*.res.nc   INPUT/*.res.nc.0???   INPUT/*.res.tile?.nc   INPUT/*.res.tile?.nc.0???
mv    RESTART/*.res RESTART/*.res.nc RESTART/*.res.nc.0??? RESTART/*.res.tile?.nc RESTART/*.res.tile?.nc.0??? INPUT
#--------------------------------------------------------------------------------------------------------
@ irun ++
end
echo "NOTE: Idealized moist model completed successfully"
exit 0
