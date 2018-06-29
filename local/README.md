# Savanna Install Notes for local Linux machines

On a local Linux machine, there are two ways to install Savanna: using a shell script or by using Spack.

If you prefer to use a shell script to install the full stack of software and libraries that form Savanna, please consult the shell script used to [install Savanna on Titan](https://github.com/CODARcode/Software_Stack_QA/blob/master/Titan/gnu/README.md).

The preferred method to install Savanna locally is to use Spack.
[Spack](https://spack.readthedocs.io) is a package management tool designed to support multiple versions and configurations of software on a wide variety of platforms and environments.
The CODAR team maintains its Spack packages at [https://github.com/CODARcode/spack](https://github.com/CODARcode/spack), under branch 'codar'.

Once you have Spack setup locally, `spack install savanna` will install Savanna for you. Alternatively, `spack install codar-cheetah` will install both Cheetah and Savanna.

