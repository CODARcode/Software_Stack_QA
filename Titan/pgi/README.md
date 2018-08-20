# Savanna Titan Install Notes

Before installing the software stack, check for an installation in `/ccs/proj/csc249/CSC249ADCD01/soft/titan.gnu6.4`.

A customized bash script is provided below (and in this directory, called `build_everything.sh`) to install all components of the codar stack. Users are encouraged to study the script and set the `INSTALL_ROOT` to point to a location where they want to install the library.

```bash
#!/bin/bash

source $MODULESHOME/init/bash
module load gcc/4.9.3
module load cmake3/3.9.0
module unload cudatoolkit
module load autoconf
module load automake
module load libtool
module load wget
module load papi
module load fastbit
module list

#set -x
set -e

WORK_DIR=$PWD
DATE=`date +%Y-%m-%d`
INSTALL_ROOT=/ccs/proj/csc249/CSC249ADCD01/soft/titan.pgi18.4.0/${DATE}

if [ ! -d ${INSTALL_ROOT} ] ; then
    mkdir -p ${INSTALL_ROOT}
fi

SZ_VERSION=1.4.12.3
ZFP_VERSION=0.5.2
LZ4_VERSION=1.8.1.2
BLOSC_VERSION=1.14.3
#DATASPACES_VERSION=develop
DATASPACES_VERSION=1.7.0
ADIOS_VERSION=develop
SQLITE3_VERSION=3200100
SOS_FLOW_VERSION=master
FFI_VERSION=3.2.1
PDT_VERSION=3.25
TAU_VERSION=2018-07-31

echo_start()
{
    echo -e "====== BUILDING $1 ======"
}

echo_done()
{
    echo -e "====== DONE BUILDING $1 ======"
}

build_sz()
{
    echo_start "sz"
    cd $WORK_DIR
    if [ ! -d SZ ] ; then
        git clone https://github.com/disheng222/SZ.git --branch v$SZ_VERSION
    fi
    cd SZ
	if [ -f Makefile ] ; then
    	make clean
	fi
    export CFLAGS=-fPIC
    export CXXFLAGS=-fPIC
    ./configure --prefix=$INSTALL_ROOT/SZ-$SZ_VERSION --disable-shared
    make -j
    make install
    cd ..
    echo_done "sz"
}

build_zfp()
{
    echo_start "zfp"
    cd $WORK_DIR
    if [ ! -d zfp ] ; then
       git clone https://github.com/LLNL/zfp.git --branch $ZFP_VERSION
    fi
    cd zfp
    rm -rf build
    mkdir build
    cd build
    export CFLAGS=-fPIC
    export CXXFLAGS=-fPIC
    cmake -DCMAKE_INSTALL_PREFIX:PATH=$INSTALL_ROOT/zfp-$ZFP_VERSION ..
    make -j
    make install
    cd ../..
    echo_done "zfp"
}

build_lz4()
{
    echo_start "lz4"
    cd $WORK_DIR
    if [ ! -d lz4 ] ; then
        git clone https://github.com/lz4/lz4.git --branch v$LZ4_VERSION
    fi
    cd lz4
	if [ -f Makefile ] ; then
    	make clean
	fi
    export CFLAGS=-fPIC
    export CXXFLAGS=-fPIC
    CC=`which gcc` CXX=`which g++` LDFLAGS=-lrt make -j install DESTDIR=$INSTALL_ROOT/lz4 prefix=''
    rm -f $INSTALL_ROOT/lz4/lib/*so*
    cd ..
    echo_done "lz4"
}

build_mgard()
{
    echo_start "mgard"
    cd $WORK_DIR
    if [ ! -d mgard ] ; then
        git clone https://code.ornl.gov/jyc/MGARD.git mgard
    fi
    cd mgard
	if [ -f Makefile ] ; then
    	make clean
	fi
    export CFLAGS=-fPIC
    export CXXFLAGS=-fPIC
    make CC=cc CXX="CC"
    mkdir $INSTALL_ROOT/mgard
    mkdir $INSTALL_ROOT/mgard/lib
    cp -r include $INSTALL_ROOT/mgard/.
    cp -r libmgard.a $INSTALL_ROOT/mgard/lib
    cd ..
    echo_done "mgard"
}

build_blosc()
{
    echo_start "blosc"
    cd $WORK_DIR
    if [ ! -d c-blosc ] ; then
        git clone https://github.com/Blosc/c-blosc.git --branch v$BLOSC_VERSION
    fi
    cd c-blosc
    rm -rf build
    mkdir build
    cd build
    export CFLAGS=-fPIC
    export CXXFLAGS=-fPIC
    cmake -DCMAKE_C_COMPILER=`which gcc` -DCMAKE_CXX_COMPILER=`which g++` -DCMAKE_INSTALL_PREFIX=$INSTALL_ROOT/blosc-$BLOSC_VERSION ../
    cmake --build .
    cmake --build . --target install
    cd ../../
    echo_done "blosc"
}

build_flexpath()
{
    module load perl
    echo_start "flexpath"
    cd $WORK_DIR
    mkdir -p flexpath
    cd flexpath
    wget -q https://gtkorvo.github.io/korvo_bootstrap.pl
    perl korvo_bootstrap.pl stable $INSTALL_ROOT/flexpath
    sed -i -e 's/nnti/% nnti/' korvo_build_config
    sed -i -e 's/enet/% enet/' korvo_build_config
    sed -i -e 's/^korvogithub configure/% korvogithub configure/' korvo_build_config
    sed -i -e 's/^korvogithub cmake/% korvogithub cmake/' korvo_build_config
    sed -i -e 's/^% korvogithub configure --/korvogithub configure --/' korvo_build_config
    sed -i -e 's/^% korvogithub cmake -/korvogithub cmake -/' korvo_build_config
    perl ./korvo_build.pl
    cd ../
    module unload perl
    echo_done "flexpath"
}

build_dataspaces()
{
    echo_start "dataspaces"
    cd $WORK_DIR
    wget http://personal.cac.rutgers.edu/TASSL/projects/data/downloads/dataspaces-$DATASPACES_VERSION.tar.gz
    tar -xf dataspaces-$DATASPACES_VERSION.tar.gz
    cd dataspaces-$DATASPACES_VERSION
    ./autogen.sh
    CC=cc FC=ftn ./configure --prefix=$INSTALL_ROOT/dataspaces-$DATASPACES_VERSION --enable-dimes --with-gni-ptag=250 --with-gni-ptag=0x5420000 --with-dimes-rdma-buffer-size=256
    make -j
    make install
    cd ..
    echo_done "dataspaces"
}

build_adios()
{
    echo_start "adios"
    cd $WORK_DIR
    
    module unload szip
    module unload hdf5
    module unload netcdf
    module unload hdf5-parallel
    module unload netcdf-hdf5parallel
    module unload fastbit

    unset EXTRA_CFLAGS
    unset EXTRA_LIBS
    export EXTRA_LIBS="-lstdc++"
    unset LDFLAGS
    export LDFLAGS="" 
    export EXTRA_CFLAGS="-lrt -lm -O2"
    export CPPFLAGS="-DMPICH_IGNORE_CXX_SEEK -DDART_DO_VERSIONING" 
    export CFLAGS="-g -fPIC ${EXTRA_CFLAGS}" 

    if [ ! -d adios-develop ] ; then
        git clone https://github.com/ornladios/ADIOS.git adios-develop
    fi
    cd adios-$ADIOS_VERSION
	if [ -f Makefile ] ; then
    	make clean
	fi
    ./autogen.sh
    ./configure --prefix=$INSTALL_ROOT/adios-$ADIOS_VERSION \
        --enable-dependency-tracking \
        --disable-maintainer-mode \
        --disable-timers \
        --disable-timer-events \
        --enable-fortran \
        --disable-static \
        --enable-shared \
        --without-infiniband \
        --with-cray-pmi=/opt/cray/pmi/default \
        --with-cray-ugni-incdir=/opt/cray/gni-headers/default/include \
        --with-cray-ugni-libdir=/opt/cray/ugni/default/lib64 \
        --with-lustre \
        --with-dataspaces=$INSTALL_ROOT/dataspaces-$DATASPACES_VERSION \
        --with-flexpath=$INSTALL_ROOT/flexpath \
        --with-sz=$INSTALL_ROOT/SZ-$SZ_VERSION \
        --with-lz4=$INSTALL_ROOT/lz4 \
        --with-blosc=$INSTALL_ROOT/blosc-$BLOSC_VERSION \
        --with-bzip2 \
        --with-zlib \
		CC=pgcc CXX=pgCC FC=pgfortran F90=pgf90 \
		MPICC=cc MPICXX=CC MPIFC=ftn MPIF90=ftn \
        LIBS="$EXTRA_LIBS" 
        # --with-mgard=$INSTALL_ROOT/mgard \
    make -j
    make install
    cd ..

    echo_done "adios"
}

build_adios_python()
{
    export LIBS=-lstdc++
    export CFLAGS=-fPIC
    export CXXFLAGS=-fPIC
    export LDFLAGS="`$INSTALL_ROOT/flexpath/bin/evpath_config -l` -Wl,-rpath,$INSTALL_ROOT/flexpath/lib"
    export PATH=$INSTALL_ROOT/adios-${ADIOS_VERSION}/bin:${PATH}
    cd adios-$ADIOS_VERSION/wrappers/numpy
    module load python_numpy/1.9.2
    make clean
    make python
    python setup.py install --prefix=$INSTALL_ROOT/adios-${ADIOS_VERSION}
	# The installation doesn't support PGI comilers. :(
    #make clean
    #export CC=cc
	#export CXX=CC
    #make MPI=y python
    #python setup_mpi.py install --prefix=$INSTALL_ROOT/adios-${ADIOS_VERSION}
	#unset CC
	#unset CXX
    module unload python_numpy
}

build_sqlite3()
{
    echo_start "sqlite3"
    subdir=sqlite-autoconf-${SQLITE3_VERSION}
    if [ ! -d ${subdir} ] ; then
        if [ ! -f ${subdir}.tar.gz ] ; then
            wget https://www.sqlite.org/2017/${subdir}.tar.gz
        fi
        tar -xzf ${subdir}.tar.gz
    fi
    cd ${subdir}
    if [ -f Makefile ] ; then
        make clean
    fi
    CC=`which gcc` CXX=`which g++` ./configure --prefix=${INSTALL_ROOT}/sqlite3-${SQLITE3_VERSION}
    # Add the -k option to ignore "makeinfo" errors
    make -j4 -k
    make install -k
    cd ..
    echo_done "sqlite3"
}

build_ffi() 
{
    echo_start "ffi"
    olddir=`pwd`
    if [ ! -d libffi-${FFI_VERSION} ] ; then
        # The github release won't "autoreconf" on Titan.  So get a configured one from UO.
        #wget https://github.com/libffi/libffi/archive/v${FFI_VERSION}.tar.gz
        #tar -xzf v${FFI_VERSION}.tar.gz
        wget http://www.nic.uoregon.edu/~khuck/libffi-${FFI_VERSION}.tar.gz
        tar -xzf libffi-${FFI_VERSION}.tar.gz
    fi
    cd libffi-${FFI_VERSION}
    CC=`which gcc` CXX=`which g++` ./configure --prefix=${INSTALL_ROOT}/libffi-${FFI_VERSION}
    make -i
    make -i install
    cd ${INSTALL_ROOT}/libffi-${FFI_VERSION}
    ln -s lib/libffi-${FFI_VERSION}/include .
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${INSTALL_ROOT}/libffi-${FFI_VERSION}/lib/pkgconfig
    CC=`which gcc` CXX=`which g++` pip install --target=${INSTALL_ROOT}/python-libs --ignore-installed cffi
    cd $olddir
    echo_done "ffi"
}

build_sos()
{
    echo_start "sos_flow"
    if [ ! -d sos_flow ] ; then
        # Clone the repository
        git clone https://github.com/cdwdirect/sos_flow.git
    fi
    cd sos_flow
    git checkout ${SOS_FLOW_VERSION}
    git pull

    rm -rf build
    mkdir build && cd build
	set -x
    export CC=pgcc
    export CXX=pgc++
    export PYTHONPATH=$PYTHONPATH:${INSTALL_ROOT}/python
    cmake \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_ROOT/sos_flow-${SOS_FLOW_VERSION} \
    -DSQLite3_DIR=$INSTALL_ROOT/sqlite3-${SQLITE3_VERSION} \
    -DEVPath_DIR=$INSTALL_ROOT/flexpath \
    -DCMAKE_C_COMPILER=${CC} \
    -DCMAKE_CXX_COMPILER=${CXX} \
    -DSOS_ENABLE_PYTHON=TRUE \
    -DBUILD_SHARED_LIBS=FALSE \
    -DSOS_CLOUD_SYNC_WITH_EVPATH=TRUE \
    -DMPI_C_NO_INTERROGATE=TRUE \
    -DSOS_FORCE_RPATH=FALSE \
    ..
	set +x
    make VERBOSE=1
    make install
    cd ../..
    echo_done "sos_flow"
}

build_pdt() {
    echo_start "pdt"
    subdir=pdtoolkit-${PDT_VERSION}
    if [ ! -d ${subdir} ] ; then
        if [ ! -f pdt-3.25.tar.gz ] ; then
            wget https://www.cs.uoregon.edu/research/tau/pdt_releases/pdt-${PDT_VERSION}.tar.gz
        fi
        tar -xzf pdt-${PDT_VERSION}.tar.gz
    fi
    cd ${subdir}
    CC=gcc CXX=g++ ./configure -GNU -prefix=${INSTALL_ROOT}/pdtoolkit-${PDT_VERSION}
    make -j4
    make install
    cd ..
    echo_done "pdt"
}

build_tau()
{
    echo_start "tau"
    if [ ! -d tau2-${TAU_VERSION} ] ; then
        if [ ! -f tau2-${TAU_VERSION}.tar.gz ] ; then
            wget http://www.nic.uoregon.edu/~khuck/tau2-${TAU_VERSION}.tar.gz
        fi
        tar -xzf tau2-${TAU_VERSION}.tar.gz
    fi
    cd tau2-${TAU_VERSION}

    PAPI_PATH=`pkg-config --cflags papi | sed -r 's/^-I//' | xargs dirname`

    # base configure for front-end tools
    CC=pgcc CXX=pgc++ ./configure \
    -prefix=${INSTALL_ROOT}/tau-${TAU_VERSION} \
    -pdt=${INSTALL_ROOT}/pdtoolkit-${PDT_VERSION} \
    -pdt_c++=g++ \
    -bfd=download -unwind=download -otf=download \
    -arch=craycnl
    make -j8 -l24 install

    # different configurations for mutually exclusive config options.
    for cuda_settings in "" "-cuda=${CUDATOOLKIT_HOME}" ; do
        for thread_settings in "-pthread" "-openmp -opari" ; do
            for python_settings in "" "-python" ; do
                # build config with all CODAR support
                ./configure \
                -prefix=${INSTALL_ROOT}/tau-${TAU_VERSION} \
                -pdt=${INSTALL_ROOT}/pdtoolkit-${PDT_VERSION} \
                -pdt_c++=g++ \
                -bfd=download -unwind=download -otf=download \
                -arch=craycnl \
                -cc=pgcc -c++=pgc++ -fortran=gfortran \
                -iowrapper -mpi \
                -adios=${INSTALL_ROOT}/adios-${ADIOS_VERSION} \
                -sos=${INSTALL_ROOT}/sos_flow-${SOS_FLOW_VERSION} \
                -papi=${PAPI_PATH} \
                ${thread_settings} ${cuda_settings} ${python_settings}
                make -j8 -l24 install
            done
        done
    done

    cd ..
    echo_done "tau"
}

#==============================================================================

# ADIOS dependencies
build_sz
build_lz4
build_blosc

# not publicly available
# build_mgard

# not used?
# build_zfp

# ADIOS dependencies
export CRAYPE_LINK_TYPE=static
build_flexpath

# ADIOS dependencies
module load craype-hugepages2M
build_dataspaces

# ADIOS
export CRAYPE_LINK_TYPE=dynamic
build_adios
module load python
build_adios_python
module unload craype-hugepages2M

# SOS
unset CRAYPE_LINK_TYPE
build_sqlite3
build_ffi
build_sos

# TAU
build_pdt
module load cudatoolkit
build_tau

rm *tar.gz

```
