SetLocal EnableDelayedExpansion

if "%cuda_compiler_version%"=="None" (
    set "FAISS_ENABLE_GPU=OFF"
    set "CUDA_CONFIG_ARGS="
) else (
    set "FAISS_ENABLE_GPU=ON"

    REM for documentation see e.g.
    REM docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html#building-for-maximum-compatibility
    REM docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html#major-components__table-cuda-toolkit-driver-versions
    REM docs.nvidia.com/cuda/cuda-compiler-driver-nvcc/index.html#gpu-feature-list

    REM for -real vs. -virtual, see cmake.org/cmake/help/latest/prop_tgt/CUDA_ARCHITECTURES.html
    REM this is to support PTX JIT compilation; see first link above or cf.
    REM devblogs.nvidia.com/cuda-pro-tip-understand-fat-binaries-jit-caching

    REM windows support start with cuda 10.0
    REM %MY_VAR:~0,2% selects first two characters
    if "%cuda_compiler_version:~0,2%"=="10" (
        set "CMAKE_CUDA_ARCHS=35-virtual;50-virtual;52-virtual;60-virtual;61-virtual;70-virtual;75-virtual;75-real"
    )
    if "%cuda_compiler_version:~0,2%"=="11" (
        REM cuda 11.0 deprecates arches 35, 50
        set "CMAKE_CUDA_ARCHS=52-virtual;60-virtual;61-virtual;70-virtual;75-virtual;80-virtual;80-real"
    )

    echo CUDA path detected as %CUDA_PATH%

    @REM set CUDA_CONFIG_ARGS=-DCMAKE_CUDA_ARCHITECTURES=!CMAKE_CUDA_ARCHS!
    REM cmake does not generate output for the call below; echo some info
    @REM echo Set up extra cmake-args: CUDA_CONFIG_ARGS=!CUDA_CONFIG_ARGS!

    REM Debug VS integrations
    set "CudaToolkitVersion=%cuda_compiler_version%"
    set "CudaToolkitDir=%CUDA_PATH%"
    set "CudaToolkitCustomDir=%CUDA_PATH%"
    set "CudaToolkitBinDir=%CUDA_PATH%\bin"
    set "CudaToolkitIncludeDir=%CUDA_PATH%\include"
    set "CudaToolkitLibDir=%CUDA_PATH%\lib\x64"
    set "CudaToolkitNvccPath=%CUDA_PATH%\bin\nvcc.exe"
    copy /y "%CUDA_PATH%\extras\visual_studio_integration\MSBuildExtensions\*.*" "%VSINSTALLDIR%\Common7\IDE\VC\VCTargets\BuildCustomizations"
    @REM set "PATH=%CUDA_PATH%\bin;%PATH%"
)

:: Build faiss.dll
cmake -B _build ^
    -DBUILD_SHARED_LIBS=ON ^
    -DBUILD_TESTING=OFF ^
    -DFAISS_ENABLE_PYTHON=OFF ^
    -DFAISS_ENABLE_GPU=!FAISS_ENABLE_GPU! ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
    -DCMAKE_INSTALL_BINDIR="%LIBRARY_BIN%" ^
    -DCMAKE_INSTALL_LIBDIR="%LIBRARY_LIB%" ^
    -DCMAKE_INSTALL_INCLUDEDIR="%LIBRARY_INC%" ^
    !CUDA_CONFIG_ARGS! ^
    .
if %ERRORLEVEL% neq 0 exit 1

cmake --build _build --config Release -j %CPU_COUNT%
if %ERRORLEVEL% neq 0 exit 1

cmake --install _build --config Release --prefix %PREFIX%
if %ERRORLEVEL% neq 0 exit 1
