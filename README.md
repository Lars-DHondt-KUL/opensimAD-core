OpenSim-based framework to solve trajectory optimization problems using direct collocation and algorithmic differentiation 
==========================================================================================================================
 
**WARNING: This repository has been forked from [Opensim's master source code](https://github.com/opensim-org/opensim-core). Changes have been
made to enable the use of algorithmic differentiation. Consequently, some features of OpenSim and Simbody have been disabled. Please rely on the original source code of OpenSim and Simbody if you do not intend to exploit algorithmic differentiation when solving trajectory optimization problems with our framework.
In addition, please make sure you verify your results. We cannot guarantee that our changes did not affect the original code.**

OpenSim is a software that lets users develop models of musculoskeletal structures and create dynamic simulations of movement. In this work,
we augmented OpenSim and created a framework for solving trajectory optimization problems using direct collocation and algorithmic differentiation.
This framework relies on OpenSim for musculoskeletal structures and multibody dynamics models and on [CasADi](https://web.casadi.org/) for nonlinear optimization and algorithmic differentiation. To enable the use of algorithmic differentiation in OpenSim, we have developed a tool named Recorder that we integrated as part of [a modified version of Simbody](https://github.com/antoinefalisse/simbody/tree/AD-recorder). More information about this framework and Recorder can be found in [this paper](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0217730).

Solving trajectory optimization problems with our framework allows generating computationally efficient predictive simulations of movement.
For example, you can produce the following predictive simulation of walking with a complex musculoskeletal models (29 degrees of freedom, 92 muscles,
and 6 contact spheres per foot) in only about 20 minutes of CPU time on a standard laptop computer:

![Predictive simulation of human walking by Antoine Falisse (doi:10.1098/rsif.2019.0402)](doc/images/opensim_predwalking.gif)

More information about how to generate such predictive simulations can be found in [this publication](https://royalsocietypublishing.org/doi/10.1098/rsif.2019.0402).

Brief overview of the framework
-------------------------------

Solving trajectory optimization problems with our framework requires the following steps:

* Build the source code of the modified versions of OpenSim and Simbody that enable the use of algorithmic differentiation ([On Windows using Microsoft Visual Studio](#on-windows-using-visual-studio)).

* Build the OpenSim code intended to be used when formulating the trajectory optimization problems ([Build external functions](#build-external-functions)). For instance, this code may perform inverse dynamics with generalized coordinate values, speeds, and accelerations as inputs and joint torques as output. We provide a series of examples of how this code may look like in the folder [OpenSim/External_Functions](https://github.com/antoinefalisse/opensim-core/tree/AD-recorder/OpenSim/External_Functions). Among the examples is the code used for generating the predictive simulation in the animation above. We will refer to this code as an external function. You should build this code as an executable.

* Run the executable ([Run executable](#run-executable)). This will generate a MATLAB file, named by default `foo.m`. This file contains the expression graph of the external function in a format that CasADi can interpret. Expression graphs are at the core of algorithmic differentiation.

* Generate C code and compile it into a dynamically linked library (dll) ([Compile external function into dll](#compile-external-function-into-dll)). From the expression graph generated in the previous step, CasADi can generate C code that contains the (external) function and its derivatives. We rely on the code generation feature of CasADi to automatically generate this C code with a few MATLAB commands. When compiled into a dll, a `Function` instance can be created using [CasADi's `external function`](https://web.casadi.org/docs/#casadi-s-external-function) and the external function can be used within the CasADi environment when formulating trajectory optimization problems.

* Formulate and solve trajectory optimization problems ([Formulate and solve trajectory optimization problems](#formulate-and-solve-trajectory-optimization-problems)). In [this repository](https://github.com/antoinefalisse/3dpredictsim), you can find code used to generate predictive simulations such as shown in the animation above. At [this line](https://github.com/antoinefalisse/3dpredictsim/blob/master/OCP/PredSim_all_v2.m#L151), we import the dll (compiled in the previous step) as an external function in our environment. We then [call this function](https://github.com/antoinefalisse/3dpredictsim/blob/master/OCP/PredSim_all_v2.m#L890) when formulating our nonlinear programming problem (NLP). When solving the problem, CasADi provides the NLP solver (e.g., IPOPT) with evaluations of the NLP objective function, constraints, objective function gradient, constraint Jacobian, and (potentially) Hessian of the Lagrangian. CasADi efficiently queries evaluation of the external function and its derivatives to construct the full derivative matrices.

Building the framework from the source code
-------------------------------------------

**NOTE -- In all platforms (Windows, OSX, Linux), it is advised to build all OpenSim Dependencies (Simbody, BTK etc) with same *CMAKE_BUILD_TYPE* (Linux) / *CONFIGURATION* (MSVC/Xcode) as OpenSim. For example, if OpenSim is to be built with *CMAKE_BUILD_TYPE/CONFIGURATION* as *Debug*, Simbody, BTK and all other OpenSim dependencies also should be built with *CMAKE_BUILD_TYPE/CONFIGURATION* as *Debug*. Failing to do so *may* result in mysterious runtime errors like 'segfault' in standard c++ library implementation.**

We have developed this project on Windows. We cannot guarantee that it works fine on other platforms. For Mac OSX and Ubuntu, you can get inspiration from the [Windows instructions](#on-windows-using-visual-studio) for the modified version of OpenSim while relying on the original instructions for Mac OSX and Ubuntu from the [OpenSim-Core git repository](https://github.com/opensim-org/opensim-core).


On Windows using Visual Studio
------------------------------

#### Get the dependencies

* **operating system**: Windows 10.
* **tool for nonlinear optimization and algorithmic differentiation**: [CasADi](https://web.casadi.org/). Install the MATLAB version.
* **version control**: [git](https://git-scm.com/downloads). Add git to your path if not done by default.
* **cross-platform build system**:
  [CMake](http://www.cmake.org/cmake/resources/software.html) >= 3.2. [Add CMake to your path](https://stackoverflow.com/questions/19176029/cmake-is-not-recognised-as-an-internal-or-external-command) if not done by default.
* **compiler / IDE**: Visual Studio [2015](https://www.visualstudio.com/vs/older-downloads/) or [2017](https://www.visualstudio.com/) (2017 requires CMake >= 3.9).
    * The *Community* variant is sufficient and is free for everyone.
    * Visual Studio 2015 and 2017 do not install C++ support by default.
      * **2015**: During the installation you must select
        *Custom*, and check *Programming Languages > Visual C++ > Common Tools
        for Visual C++ 2015*.
        You can uncheck all other boxes. If you have already installed
        Visual Studio without C++ support, simply re-run the installer and
        select *Modify*. Alternatively, go to *File > New > Project...* in
        Visual Studio, select *Visual C++*, and click
        *Install Visual C++ 2015 Tools for Windows Desktop*.
      * **2017**: During the installation, select the workload
        *Desktop Development with C++*.
      * If Visual Studio is installed without C++ support, CMake will report
        the following errors:
        ```
        The C compiler identification is unknown
        The CXX compiler identification is unknown
        ```
* **physics engine**: Simbody - AD version. Two options:
    * Let OpenSim get this for you using superbuild (see below); much easier!
    * [Build on your own: be careful you need to build the modified version that enables the use of AD](
      https://github.com/antoinefalisse/simbody/tree/AD-recorder#windows-using-visual-studio).
* **C3D file support**: Biomechanical-ToolKit Core. Two options:
    * Let OpenSim get this for you using superbuild (see below); much easier!
    * [Build on your own](https://github.com/klshrinidhi/BTKCore).
* **command-line argument parsing**: docopt.cpp. Two options:
    * Let OpenSim get this for you using superbuild (see below); much easier!
    * [Build on your own](https://github.com/docopt/docopt.cpp) (no instructions).

#### Download OpenSim's source code modified to enable the use of algorithmic differentiation (OpenSim-AD-Core)

* Clone the opensim-ad-core git repository. We'll assume you clone it into `C:/opensim-ad/opensim-ad-core`.
  **Be careful that the repository is not on the `master` branch but on the `AD-recorder-matpy` branch.** 

  Run the following in the command prompt :
  
        git clone -b AD-recorder-matpy https://github.com/Lars-DHondt-KUL/opensimAD-core.git C:/opensim-ad/opensim-ad-core  

#### [RECOMMENDED] Superbuild: download and build OpenSim dependencies
1. Open the CMake GUI.
2. In the field **Where is the source code**, specify
   `C:/opensim-ad/opensim-ad-core/dependencies`.
3. In the field **Where to build the binaries**, specify a directory under
   which to build dependencies. Let's say this is
   `C:/opensim-ad/opensim-ad-dependencies/opensim-ad-dependencies-build`.
4. Click the **Configure** button.
    1. Visual Studio 2015: Choose the *Visual Studio 14 2015* generator. (may appear as *Visual Studio 14*).
    2. Visual Studio 2017: Choose the *Visual Studio 15 2017* generator.
    3. Make sure you build as 64-bit, select the generator with *Win64* in the name.
    4. Click **Finish**.
5. Where do you want to install OpenSim dependencies on your computer? Set this
   by changing the `CMAKE_INSTALL_PREFIX` variable. Let's say this is
   `C:/opensim-ad/opensim-ad-dependencies/opensim-ad-dependencies-install`.
6. Variables named `SUPERBUILD_<dependency-name>` allow you to selectively
   download dependencies. By default, all dependencies are downloaded,
   configured, and built.
7. Click the **Configure** button again. Then, click **Generate** to make
   Visual Studio project files in the build directory.
8. Go to the build directory you specified in step 3 by typing the following in the command prompt:

        cd C:/opensim-ad/opensim-ad-dependencies/opensim-ad-dependencies-build

9. Use CMake to download, compile, and install the dependencies (don't worry about the warnings):

        cmake --build . --config RelWithDebInfo

   Building in **RelWithDebInfo** mode is fine and sufficient for our applications. Yet alternative values for `--config` in this command are:
   
   * **Debug**: debugger symbols; no optimizations (more than 10x slower).
     Library names end with `_d`.
   * **Release**: no debugger symbols; optimized.
   * **RelWithDebInfo**: debugger symbols; optimized. Bigger but not slower
     than Release; choose this if unsure.
   * **MinSizeRel**: minimum size; optimized.
10. If you like, you can now remove the directory used for building
    dependencies (`C:/opensim-ad/opensim-ad-dependencies/opensim-ad-dependencies-build`).

#### Configure and generate project files

1. Open the CMake GUI.
2. In the field **Where is the source code**, specify `C:/opensim-ad/opensim-ad-core`.
3. In the field **Where to build the binaries**, specify something like
   `C:/opensim-ad/opensim-ad-core-build`, or some other path that is not inside your source
   directory. This is *not* where we are installing OpenSim-Core; see below.
4. Click the **Configure** button.
    1. Visual Studio 2015: Choose the *Visual Studio 14* or *Visual Studio 14 2015* generator.
    2. Visual Studio 2017: Choose the *Visual Studio 15 2017* generator.
    3. Make sure you build as 64-bit, select the generator with *Win64* in the name.
    4. Click **Finish**.
5. Where do you want to install OpenSim-AD-Core on your computer? Set this by
   changing the `CMAKE_INSTALL_PREFIX` variable. We'll assume you set it to
   `C:/opensim-ad/opensim-ad-core-install`.
6. Tell CMake where to find dependencies. This depends on how you got them.
    * If you used the superbuild (RECOMMENDED): Set the variable `OPENSIM_DEPENDENCIES_DIR` to the root
      directory you specified with superbuild for installation of dependencies.
      In our example, it would be `C:/opensim-ad/opensim-ad-dependencies/opensim-ad-dependencies-install`.
    * If you obtained the dependencies on your own:
        1. Simbody: Set the `SIMBODY_HOME` variable to where you installed
           Simbody (e.g., `C:/Simbody-ad-install`).
        2. BTK: Set the variable `BTK_DIR` to the directory containing
           `BTKConfig.cmake`. If the root directory of your BTK installation is
           `C:/BTKCore-install`, then set this variable to
           `C:/BTKCore-install/share/btk-0.4dev`.
        3. docopt.cpp. Set the variable `docopt_DIR` to the directory
           containing `docopt-config.cmake`. If the root directory of your 
           docopt.cpp installation is `C:/docopt.cpp-install`, then set this 
           variable to `C:/docopt.cpp-install/lib/cmake`.
7. Set the remaining configuration options.
    * `WITH_RECORDER` to compile OpenSim modified to enable the use of algorithmic differentiation. You should turn this on.
    * `BUILD_EXTERNAL_FUNCTIONS` to build the external functions. You should turn this on.  
    * `BUILD_API_EXAMPLES` to compile C++ API examples. Note that most examples will not work with this modified version of OpenSim. You could turn this off.
    * `BUILD_TESTING` to ensure that OpenSim works correctly. Note that most tests will fail with this modified version of OpenSim. You could turn this off.
    * `BUILD_JAVA_WRAPPING` if you want to access OpenSim through MATLAB or
      Java; see dependencies above. Please turn this off (not relevant for our applications).
    * `BUILD_PYTHON_WRAPPING` if you want to access OpenSim through Python; see
      dependencies above. CMake sets `PYTHON_*` variables to tell you the
      Python version used when building the wrappers. Please turn this off (not relevant for our applications).
    * `OPENSIM_PYTHON_VERSION` to choose if the Python wrapping is built for
      Python 2 or Python 3. Leave to 2 (not relevant for our applications).
    * `BUILD_API_ONLY` if you don't want to build the command-line applications.
8. Click the **Configure** button again. Then, click **Generate** to make
   Visual Studio project files in the build directory.

9. Go to Open `C:/opensim-ad/opensim-ad-core-build/` 

10. Use CMake to compile, and install the software:

        cmake --build . --config RelWithDebInfo

 

