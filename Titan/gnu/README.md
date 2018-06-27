# Savanna Titan Install Notes

Before installing the software stack, check for an installation in `/lustre/atlas/proj-shared/csc249/CSC249ADCD01/software/titan.gnu/gcc-6.3.0/`. 

A customized bash script is provided below to install all components of the codar stack. Users are encouraged to study the script and set the `INSTALL_ROOT` to point to a location where they want to install the library.

```
#!/bin/bash


source $MODULESHOME/init/bash
module load cmake3/3.9.0
module unload gcc
module load gcc/6.3.0
module unload cudatoolkit
module load autoconf
module load automake
module load wget
module load perl
module list

set -x

WORK_DIR=$PWD
INSTALL_ROOT=/lustre/atlas/proj-shared/csc249/CSC249ADCD01/software/titan.gnu/gcc-6.3.0

SZ_VERSION=1.4.12.3
ZFP_VERSION=0.5.2
LZ4_VERSION=1.8.1.2
BLOSC_VERSION=1.14.3
DATASPACES_VERSION=develop
ADIOS_VERSION=develop

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
    git clone https://github.com/disheng222/SZ.git --branch v$SZ_VERSION
    cd SZ
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
    git clone https://github.com/LLNL/zfp.git --branch $ZFP_VERSION
    cd zfp
    mkdir build
    cd build
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
    git clone https://github.com/lz4/lz4.git --branch v$LZ4_VERSION
    cd lz4
    make -j install DESTDIR=$INSTALL_ROOT/lz4 prefix=''
    rm -f $INSTALL_ROOT/lz4/lib/*so*
    cd ..
    echo_done "lz4"
}

build_mgard()
{
    echo_start "mgard"
    cd $WORK_DIR
    cd mgard
    make clean
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
    git clone https://github.com/Blosc/c-blosc.git --branch v$BLOSC_VERSION
    cd c-blosc
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_ROOT/blosc-$BLOSC_VERSION ../
    cmake --build .
    cmake --build . --target install
    cd ../../
    echo_end "blosc"
}

build_flexpath()
{
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
    unset LDFLAGS
    export LDFLAGS="" 
    export EXTRA_CFLAGS="-Ofast -lrt -lm -O2"
    export CPPFLAGS="-DMPICH_IGNORE_CXX_SEEK -DDART_DO_VERSIONING" 
    export CFLAGS="-g -fPIC ${EXTRA_CFLAGS}" 

    git clone https://github.com/ornladios/ADIOS.git adios-develop
    cd adios-$ADIOS_VERSION
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
        --with-mgard=$INSTALL_ROOT/mgard \
        --with-blosc=$INSTALL_ROOT/blosc-$BLOSC_VERSION \
        --with-bzip2 \
        --with-zlib \
        CC=cc CXX=CC FC=ftn \
        LDFLAGS="-zmuldefs" \
        LIBS="$EXTRA_LIBS" 
    make -j
    make install
    cd ..

    echo_done "adios"
}

#==============================================================================
build_sz
build_lz4
build_mgard
build_blosc
export CRAYPE_LINK_TYPE=static
build_flexpath

module load craype-hugepages2M
build_dataspaces
export CRAYPE_LINK_TYPE=dynamic
build_adios

rm *tar.gz
```
