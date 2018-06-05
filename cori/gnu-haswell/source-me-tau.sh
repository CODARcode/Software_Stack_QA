CODAR_BASE=/global/project/projectdirs/m3084/cluster2018
SPACK_HOME=$CODAR_BASE/sw/spack
source $SPACK_HOME/share/spack/setup-env.sh

module unload darshan
module sw PrgEnv-intel PrgEnv-gnu
module load python/3.6-anaconda-4.4

export PATH=$CODAR_BASE/sw/cheetah:$PATH

source $CODAR_BASE/tau/sourceme-cori-gcc.sh

spack load adios lz4 bzip2 mgard zlib zfp dataspaces c-blosc

# Needed for building with TAU+SOS
export CRAYPE_LINK_TYPE=dynamic

export TAU_PLUGINS=libTAU-sos-plugin.so
export TAU_PLUGINS_PATH=$TAU_ROOT/craycnl/lib/shared-gnu-papi-mpi-pthread-pdt-sos-adios
