#!/bin/bash -euo

wget https://archives.boost.io/release/1.78.0/source/boost_1_78_0.tar.gz

mv boost_1_78_0.tar.gz vendor/boost-1.55-bamrc.tar.gz

mkdir -p "${PREFIX}/bin"

sed -i.bak -e 's|2.8.3|3.10|' CMakeLists.txt
rm -rf *.bak
sed -i.bak -e 's|2.8|3.10|' cmake/BuildSamtools.cmake
sed -i.bak -e 's|2.8|3.10|' cmake/BuildBoost.cmake
rm -rf cmake/*.bak

# Needed for building utils dependency
export INCLUDES="-I${PREFIX}/include"
export LIBPATH="-L${PREFIX}/lib"
export LDFLAGS="${LDFLAGS} -pthread -L${PREFIX}/lib"
export CXXFLAGS="${CXXFLAGS} -O3"
export CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include"

if [[ `uname` == Darwin ]]; then
	export LDFLAGS="${LDFLAGS} -Wl,-rpath,${PREFIX}/lib"
	# See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk for -D_LIBCPP_DISABLE_AVAILABILITY
	export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
	export CONFIG_ARGS="-DCMAKE_FIND_FRAMEWORK=NEVER -DCMAKE_FIND_APPBUNDLE=NEVER"
	export CFLAGS="${CFLAGS} -O3 -fno-define-target-os-macros -Wno-unguarded-availability -Wno-deprecated-non-prototype -Wno-implicit-function-declaration"
else
	export CONFIG_ARGS=""
fi

if [[ `uname` == "Darwin" ]]; then
	ln -sf ${CC} ${BUILD_PREFIX}/bin/clang
	ln -sf ${CXX} ${BUILD_PREFIX}/bin/clang++
else
	ln -sf ${CC} ${BUILD_PREFIX}/bin/gcc
	ln -sf ${CXX} ${BUILD_PREFIX}/bin/g++
fi

cmake -S . -B build -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_CXX_COMPILER="${CXX}" \
	-DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
	-DCMAKE_C_COMPILER="${CC}" \
	-DCMAKE_C_FLAGS="${CFLAGS}" \
	-Wno-dev -Wno-deprecated --no-warn-unused-cli \
	"${CONFIG_ARGS}"

cmake --build build --clean-first -j "${CPU_COUNT}" -v

install -v -m 0755 build/bin/bam-readcount "${PREFIX}/bin"
