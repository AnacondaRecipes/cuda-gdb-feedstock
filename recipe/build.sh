#!/bin/bash

# Install to conda style directories
[[ -d lib64 ]] && mv lib64 lib

[[ ${target_platform} == "linux-64" ]] && targetsDir="targets/x86_64-linux"
[[ ${target_platform} == "linux-ppc64le" ]] && targetsDir="targets/ppc64le-linux"
[[ ${target_platform} == "linux-aarch64" ]] && targetsDir="targets/sbsa-linux"

for i in `ls`; do
    [[ $i == "build_env_setup.sh" ]] && continue
    [[ $i == "conda_build.sh" ]] && continue
    [[ $i == "metadata_conda_debug.yaml" ]] && continue

    if [[ $i == "bin" ]]; then
        for j in `ls "${i}"`; do
            [[ -f "bin/${j}" ]] || continue
            [[ ${j} == "cuda-gdb" && ${target_platform} == "linux-64" ]] && continue # cuda-gdb is a shell script for linux-64

            echo patchelf --force-rpath --set-rpath "\$ORIGIN/../lib:\$ORIGIN/../${targetsDir}/lib" "${i}/${j}" ...
            patchelf --force-rpath --set-rpath "\$ORIGIN/../lib:\$ORIGIN/../${targetsDir}/lib" "${i}/${j}"
        done
    fi

    cp -rv $i ${PREFIX}
done

check-glibc "$PREFIX"/lib*/*.so.* "$PREFIX"/bin/* "$PREFIX"/targets/*/lib*/*.so.* "$PREFIX"/targets/*/bin/*
