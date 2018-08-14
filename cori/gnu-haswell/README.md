# Savanna Cori Install Notes

Before installing anything from scratch, check for an up to date install in
`/global/project/projectdirs/m3084/`. To update or create a new configuration,
use the following as a starting point. Before building anything, switch to the
gnu compiler chain:
```
module sw PrgEnv-intel PrgEnv-gnu
module unload darshan
```

1. Install EVPath and related libraries using
    [Korvo Bootstrap](https://gtkorvo.github.io/), development tag.
    Consider using a shared location in `/global/project/projectdirs/m3084/soft`
    with compiler and date prefixes:
    ```
    CODAR_HOME=/global/project/projectdirs/m3084/soft/cori.gnu7.3/2018-08-14
    mkdir -p $CODAR_HOME/korvo_build
    cd $CODAR_HOME/korvo_build
    wget -q https://gtkorvo.github.io/korvo_bootstrap.pl
    perl ./korvo_bootstrap.pl development $CODAR_HOME/korvo
    perl ./korvo_build.pl
    ```

2. Install [spack](http://spack.readthedocs.io/en/latest/getting_started.html)
    from the `CODARcode` fork and `codar-theta` branch (not a typo - branch
    includes changes for both theta and cori):
    ```
    cd $CODAR_HOME
    git clone --branch codar-theta git@github.com:CODARcode/spack.git
    ```
    Note: use the codar branch once these changes have been merged.

3. Copy `packages.yaml` and `mirrors.yaml` from this directory to
    `$CODAR_HOME/etc/spack/`. Double check that the gnu compiler version has
    not changed, and update if needed, along with the cray-mpich path.
    Edit korvo paths in `packages.yaml` to point at
    the location of the installed GTkorvo libraries. The mirrors file points at
    a spack mirror with version of dataspaces and mgard that are not available
    for public download. IMPORTANT: remove or rename `~/.spack`, it takes
    precedence over the per-install configuration and makes it difficult to
    have multiple spack installations.

4. Install adios and dependencies using spack. Note that this will use the
    cray system MPI and other standard tools, as well as the GTkorvo libraries
    built above if packages.yaml is set up correctly. It will also use the
    versions and variants specified in that file, so they don't need to be
    set in the install line.
    ```
    spack install adios
    ```

5. Checkout and build heat transfer example using cluster-2018 branch:
    ```
    git checkout git@github.com:CODARcode/Example-Heat_Transfer.git
    cd Example-Heat_Transfer
    git checkout cluster-2018
    spack load adios bzip2 lz4 zfp mgard
    make
    cd stage_write
    make
    cd ..
    ```

# SOS, TAU Install notes

As stated above, before installing anything from scratch, check for the latest software in `/projects/CSC249ADCD01/`. 
Before building anything, switch to the gnu compiler chain and uninstall the darshan module, and optionally load the PAPI module:
```
module sw PrgEnv-intel PrgEnv-gnu
module unload darshan
module load papi
```

1. Install SQLite3
```
wget https://www.sqlite.org/2017/sqlite-autoconf-3200100.tar.gz
tar -xvf sqlite-autoconf-3200100.tar.gz
cd sqlite-autoconf-3200100
CC=`which gcc` CXX=`which g++` ./configure --prefix=/global/project/projectdirs/m3084/tau/sqlite3
make -k
make install -k
```

2. Install SOS
SOS has a dependency on EVPath and SQLite3.  It also requres the cmake/3.3.2 module on Cori.  Because the Cray compiler wrappers default to static linking (and because EVPath was built as static libraries), SOS needs to be configured for static linking.  To do this, we use the options ```-DBUILD_SHARED_LIBS=FALSE``` and ```-DSOS_FORCE_RPATH=FALSE```.

```
module load cmake/3.3.2
git clone https://github.com/cdwdirect/sos_flow.git
cd sos_flow
mkdir build
cd build
export CC=cc
export CXX=CC
cmake \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_INSTALL_PREFIX=/global/project/projectdirs/m3084/tau/sos_flow \
    -DSQLite3_DIR=/global/project/projectdirs/m3084/tau/sqlite3 \
    -DEVPath_DIR=/global/project/projectdirs/m3084/cluster2018/sw/korvo \
    -DCMAKE_C_COMPILER=cc \
    -DCMAKE_CXX_COMPILER=CC \
    -DSOS_ENABLE_PYTHON=TRUE \
    -DBUILD_SHARED_LIBS=FALSE \
    -DSOS_CLOUD_SYNC_WITH_EVPATH=TRUE \
    -DMPI_C_NO_INTERROGATE=TRUE \
    -DSOS_FORCE_RPATH=FALSE \
    ..
make -j4
make install
```

3. Install PDT
PDT is a large download, and is only required for auto-instrumentation of source code by TAU.
```
wget http://tau.uoregon.edu/pdt.tgz
tar -xzf pdt.tgz
cd pdtoolkit-3.25
CC=gcc CXX=g++ ./configure -GNU -prefix=/global/project/projectdirs/m3084/tau/pdt
make install
```

4. Install TAU
TAU has a dependency on PDT, SOS, ADIOS, PAPI.  TAU also needs to be configured and built for different runtime uses, in particular for systems where compute nodes and head nodes are different operating systems or environments (like Cori).

* first, build the TAU front-end tools.
    
```
# The latest official release of TAU is tau.tgz, the current working master is tau2.tgz
wget http://tau.uoregon.edu/tau2.tgz
tar -xzf tau2.tgz
cd tau-2.27
CC=gcc CXX=g++ ./configure \
    -prefix=/global/project/projectdirs/m3084/tau/tau \
    -bfd=download -unwind=download \
    -pdt=/global/project/projectdirs/m3084/tau/pdt \
    -pdt_c++=g++
make install
```

* second, build the TAU compute node environment with binutils and libunwind compiled with GCC

```
CC=gcc CXX=g++ ./configure \
    -prefix=/global/project/projectdirs/m3084/tau/tau \
    -arch=craycnl \
    -bfd=download -unwind=download \
    -pdt=/global/project/projectdirs/m3084/tau/pdt \
    -pdt_c++=g++
make install
```

* finally, build the TAU configuration we will use on the compute nodes

````
# Get the path to PAPI, ADIOS from the module and Spack
export PAPI_PATH=`pkg-config --cflags papi | sed -r 's/^-I//' | xargs dirname`
export ADIOS_DIR="$( cd "$( dirname `which adios_config` )" && pwd )"
./configure \
    -arch=craycnl \
    -cc=gcc -c++=g++ -fortran=gfortran \
    -iowrapper -mpi -pthread -bfd=download -unwind=download \
    -pdt=/global/project/projectdirs/m3084/tau/pdt \
    -pdt_c++=g++ \
    -prefix=/global/project/projectdirs/m3084/tau/tau \
    -sos=/global/project/projectdirs/m3084/tau/sos_flow \
    -adios=${ADIOS_DIR} \
    -papi=${PAPI_PATH}
make install
````
