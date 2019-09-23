#!/usr/bin/env bash

# Important: set -ex causes this whole script to terminate with error if
# any command in it fails. This is crucial for CI tests.
set -ex

# This script is run when CI system first starts up.
# It expects that ci-setenv.bash was run first, so $PLATFORM and $ARCH
# have been set.

if [[ -e src/build-scripts/ci-setenv.bash ]] ; then
    source src/build-scripts/ci-setenv.bash
fi

if [[ ! -e build/$PLATFORM ]] ; then
    mkdir -p build/$PLATFORM
fi
if [[ ! -e dist/$PLATFORM ]] ; then
    mkdir -p dist/$PLATFORM
fi

if [[ "$ARCH" == "windows64" ]] ; then
    pushd build/$PLATFORM
    cmake ../.. -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
        -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH" \
        -DCMAKE_INSTALL_PREFIX="$OPENIMAGEIO_ROOT_DIR" \
        -DPYTHON_VERSION="$PYTHON_VERSION" \
        $MY_CMAKE_FLAGS -DVERBOSE=1
    echo "Parallel build $CMAKE_BUILD_PARALLEL_LEVEL"
    VERBOSE=1
    time cmake --build . --target install --config ${CMAKE_BUILD_TYPE}
    popd
    echo "post-build PATH = $PATH"
    uname -a
else
    make $MAKEFLAGS VERBOSE=1 $BUILD_FLAGS cmakesetup
    make $MAKEFLAGS $PAR_MAKEFLAGS $BUILD_FLAGS $BUILDTARGET
fi

echo "OPENIMAGEIO_ROOT_DIR $OPENIMAGEIO_ROOT_DIR"
ls -R -l "$OPENIMAGEIO_ROOT_DIR"

if [[ "$SKIP_TESTS" == "" ]] ; then
    $OPENIMAGEIO_ROOT_DIR/bin/oiiotool --help
    make $BUILD_FLAGS test
fi

if [[ "$BUILDTARGET" == clang-format ]] ; then
    git diff --color
    THEDIFF=`git diff`
    if [[ "$THEDIFF" != "" ]] ; then
        echo "git diff was not empty. Failing clang-format or clang-tidy check."
        exit 1
    fi
fi

if [[ "$CODECOV" == 1 ]] ; then
    bash <(curl -s https://codecov.io/bash)
fi
