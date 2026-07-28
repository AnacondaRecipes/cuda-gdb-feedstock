#!/bin/bash

# Install to conda style directories
[[ -d lib64 ]] && mv lib64 lib

[[ ${target_platform} == "linux-64" ]] && targetsDir="targets/x86_64-linux"
[[ ${target_platform} == "linux-ppc64le" ]] && targetsDir="targets/ppc64le-linux"
[[ ${target_platform} == "linux-aarch64" ]] && targetsDir="targets/sbsa-linux"

mkdir -p "${PREFIX}/${targetsDir}"
mv -v extras/Debugger/include "${PREFIX}/${targetsDir}"

rm bin/cuda-gdb
if [[ ${PY_VER:-0} == "0" || ${skip_python} == "true" ]]; then
    mv -v "bin/cuda-gdb-minimal" bin/cuda-gdb
else
    mv -v "bin/cuda-gdb-python${PY_VER}-tui" bin/cuda-gdb
fi

# Fixes an issue caused by build differences between conda-forge and distro ncurses builds.
# conda-forge has separate libraries for libtinfo and libtinfow. Loading both simultaneously
# causes a segmentation fault due to duplicated global state.
patchelf --replace-needed libtinfo.so.6 libtinfow.so.6 bin/cuda-gdb

for i in `ls`; do
    [[ $i == "build_env_setup.sh" ]] && continue
    [[ $i == "conda_build.sh" ]] && continue
    [[ $i == "metadata_conda_debug.yaml" ]] && continue

    if [[ $i == "bin" ]]; then
        for j in `ls "${i}"`; do
            [[ -f "bin/${j}" ]] || continue

            echo patchelf --force-rpath --set-rpath "\$ORIGIN/../lib:\$ORIGIN/../${targetsDir}/lib" "${i}/${j}" ...
            patchelf --force-rpath --set-rpath "\$ORIGIN/../lib:\$ORIGIN/../${targetsDir}/lib" "${i}/${j}"
        done
    fi

    cp -rv $i ${PREFIX}
done

check-glibc "$PREFIX"/lib*/*.so.* "$PREFIX"/bin/* "$PREFIX"/targets/*/lib*/*.so.* "$PREFIX"/targets/*/bin/*
