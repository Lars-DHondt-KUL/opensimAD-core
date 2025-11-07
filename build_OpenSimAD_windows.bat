@echo off
setlocal enabledelayedexpansion

:: Turn off compiler warnings? (1 = yes, 0 = no)
set DISABLE_WARNINGS=1

set CMAKE_GENERATOR="Visual Studio 15 2017 Win64"
::set CMAKE_GENERATOR="Visual Studio 16 2019"

:: set VCVARS_BAT="C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
set VCVARS_BAT=



:: Set root path (modify as needed)
set OPENSIMAD_ROOT=C:\GBW_MyPrograms\OpenSimAD-lib
set OPENSIMAD_BUILD_VERSION=


:: Set paths
set OPENSIMAD_SOURCE=%OPENSIMAD_ROOT%\opensim-ad-core
set OPENSIMAD_DEPENDENCIES_BUILD=%OPENSIMAD_ROOT%\opensim-ad-dependencies-build%OPENSIMAD_BUILD_VERSION%
set OPENSIMAD_DEPENDENCIES_INSTALL=%OPENSIMAD_ROOT%\opensim-ad-dependencies-install%OPENSIMAD_BUILD_VERSION%
set OPENSIMAD_CORE_BUILD=%OPENSIMAD_ROOT%\opensim-ad-core-build%OPENSIMAD_BUILD_VERSION%
set OPENSIMAD_CORE_INSTALL=%OPENSIMAD_ROOT%\opensim-ad-core-install%OPENSIMAD_BUILD_VERSION%

:: Set warning flags
if %DISABLE_WARNINGS% equ 1 (
    ::set CMAKE_CXX_FLAGS=-W0
	set CMAKE_CXX_FLAGS=/w
) else (
    set CMAKE_CXX_FLAGS=
)

:: Clone OpenSim-AD-Core (if not already cloned)
if not exist "%OPENSIMAD_SOURCE%" (
    echo Cloning OpenSim-AD-Core...
    git clone -b AD-recorder-matpy https://github.com/Lars-DHondt-KUL/opensimAD-core.git "%OPENSIMAD_SOURCE%"
) else (
    echo OpenSim-AD-Core already exists. Skipping clone.
)

:: Configure and build dependencies
echo Configuring and building dependencies...
mkdir "%OPENSIMAD_DEPENDENCIES_BUILD%" 2>nul
cd /d "%OPENSIMAD_DEPENDENCIES_BUILD%"
if defined VCVARS_BAT call %VCVARS_BAT%
cmake -G %CMAKE_GENERATOR% ^
      -DCMAKE_INSTALL_PREFIX="%OPENSIMAD_DEPENDENCIES_INSTALL%" ^
	  -DCMAKE_CXX_FLAGS="%CMAKE_CXX_FLAGS%" ^
      "%OPENSIMAD_SOURCE%\dependencies"
cmake --build . --config Release
if %ERRORLEVEL% neq 0 (
    echo Dependency build failed.
    pause
    exit /b 1
)

:: Configure OpenSim-AD-Core
echo Configuring OpenSim-AD-Core...
mkdir "%OPENSIMAD_CORE_BUILD%" 2>nul
mkdir "%OPENSIMAD_CORE_BUILD%\Release" 2>nul
cd /d "%OPENSIMAD_CORE_BUILD%"
if defined VCVARS_BAT call %VCVARS_BAT%
cmake -G %CMAKE_GENERATOR% ^
      -DCMAKE_INSTALL_PREFIX="%OPENSIMAD_CORE_INSTALL%" ^
      -DOPENSIM_DEPENDENCIES_DIR="%OPENSIMAD_DEPENDENCIES_INSTALL%" ^
      -DWITH_RECORDER=ON ^
      -DBUILD_EXTERNAL_FUNCTIONS=OFF ^
      -DBUILD_API_EXAMPLES=OFF ^
      -DBUILD_TESTING=OFF ^
      -DBUILD_JAVA_WRAPPING=OFF ^
      -DBUILD_PYTHON_WRAPPING=OFF ^
	  -DCMAKE_CXX_FLAGS="%CMAKE_CXX_FLAGS%" ^
      "%OPENSIMAD_SOURCE%"
if %ERRORLEVEL% neq 0 (
    echo OpenSimAD-core configuration failed.
    pause
    exit /b 1
)

:: Build and install OpenSimAD-core
echo Building and installing OpenSimAD-core...
cmake --build . --config Release
cmake --install . --config Release
if %ERRORLEVEL% neq 0 (
    echo OpenSimAD-core build failed.
    pause
    exit /b 1
)

echo Build completed successfully!
pause
