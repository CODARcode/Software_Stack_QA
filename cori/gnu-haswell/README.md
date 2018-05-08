# Savanna Cori Install Notes

Before installing anything from scratch, check for an up to date install in
`/global/project/projectdirs/m3084/`. To update or create a new configuration,
use the following as a starting point. Before building anything, switch to the
gnu compiler chain:
```
module sw PrgEnv-intel PrgEnv-gnu
```
TODO: consider doing `module unload darshan` first.

1. Install EVPath and related libraries using
    [Korvo Bootstrap](https://gtkorvo.github.io/). Consider using a shared
    location in `/global/project/projectdirs/m3084/`.
    ```
    wget -q https://gtkorvo.github.io/korvo_bootstrap.pl
    perl ./korvo_bootstrap.pl stable /global/project/projectdirs/m3084/your/sw/directory
    perl ./korvo_build.pl
    ```

2. Install [spack](http://spack.readthedocs.io/en/latest/getting_started.html)
    from the `CODARcode` fork and `codar-theta` branch (not a typo - branch
    includes changes for both theta and cori):
    ```
    git clone --branch codar-theta git@github.com:CODARcode/spack.git
    ```
    Note: use the codar branch once these changes have been merged.

3. Copy `packages.yaml` and `mirrors.yaml` from this directory to
 `~/.spack/`. Edit korvo paths in `packages.yaml` to point at
 the location of the installed GTkorvo libraries. The mirrors file points at
 a spack mirror with version of dataspaces and mgard that are not available
 for public download.

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
CC=`which gcc` CXX=`which g++` ./configure --prefix=/projects/CSC249ADCD01/your/sw/directory
make -k
make install -k
```

2. Install SOS
SOS has a dependency on EVPath and SQLite3.  It also requres the cmake/3.3.2 module on Cori.
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
    -DCMAKE_INSTALL_PREFIX=/projects/CSC249ADCD01/your/sw/directory \
    -DSQLite3_DIR=/projects/CSC249ADCD01/tau/sqlite3 \
    -DEVPath_DIR=/projects/CSC249ADCD01/sw/korvo \
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
CC=gcc CXX=g++ ./configure -GNU -prefix=/projects/CSC249ADCD01/your/sw/directory
make install
```

4. Install TAU
TAU has a dependency on PDT, SOS, ADIOS, PAPI.
```
TBD
```
