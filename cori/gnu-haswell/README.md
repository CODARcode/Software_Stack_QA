# Savanna Cori Install Notes

Before installing anything from scratch, check for an up to date install in
`/global/project/projectdirs/m3084/`. To update or create a new configuration,
use the following as a starting point. Before building anything, switch to the
gnu compiler chain:

    module sw PrgEnv-intel PrgEnv-gnu

1. Install EVPath and related libraries using
 [Korvo Bootstrap](https://gtkorvo.github.io/). Consider using a shared
 location in `/global/project/projectdirs/m3084/`.

2. Install [spack](http://spack.readthedocs.io/en/latest/getting_started.html)
 from the `CODARcode` fork and `codar-theta` branch (not a typo - branch
 includes changes for both theta and cori):

    git clone --branch codar-theta git@github.com:CODARcode/spack.git

 Note: use the codar branch once these changes have been merged.

3. Copy `codar/cori/packages.yaml` to `~/.spack/packages.yaml`. Edit korvo
 paths to point at location of installed GTkorvo libraries.

4. Install adios and dependencies using spack. Note that this will use the
 cray system MPI and other standard tools, as well as the GTkorvo libraries
 built above if packages.yaml is set up correctly. It will also use the
 versions and variants specified in that file, so they don't need to be
 set in the install line.

    spack install adios

5. Checkout and build heat transfer example:

    git checkout git@github.com:CODARcode/Example-Heat_Transfer.git
    cd Example-Heat_Transfer
    spack load adios bzip2 lz4 zfp mgard
    make
    cd stage_write
    make
    cd ..
