#!/bin/bash

[[ ${target_platform} == "linux-64" ]] && targetsDir="targets/x86_64-linux"
[[ ${target_platform} == "linux-ppc64le" ]] && targetsDir="targets/ppc64le-linux"
[[ ${target_platform} == "linux-aarch64" ]] && targetsDir="targets/sbsa-linux"

errors=""

# Test only the specific binaries that should be from the cuda-gdb package
cuda_gdb_binaries=("cuda-gdb" "cuda-gdbserver")

for binary_name in "${cuda_gdb_binaries[@]}"; do
    bin="${PREFIX}/bin/${binary_name}"
    
    # Skip if binary doesn't exist
    if [[ ! -f "${bin}" ]]; then
        echo "Binary not found: ${bin}"
        continue
    fi
    
    # Skip linux-64 cuda-gdb as it's a shell script
    [[ "${binary_name}" == "cuda-gdb" && ${target_platform} == "linux-64" ]] && continue
    
    echo "Artifact to test: ${binary_name}"

    pkg_info=$(conda package -w "${bin}")
    echo "\$PKG_NAME: ${PKG_NAME}"
    echo "\$pkg_info: ${pkg_info}"

    if [[ ! "$pkg_info" == *"$PKG_NAME"* ]]; then
        echo "Not a match, skipping ${bin}"
        continue
    fi

    echo "Match found, testing ${bin}"

    rpath=$(patchelf --print-rpath "${bin}")
    echo "${bin} rpath: ${rpath}"

    if [[ $rpath != "\$ORIGIN/../lib:\$ORIGIN/../${targetsDir}/lib" ]]; then
        errors+="${bin}\n"
    elif [[ $(objdump -x ${bin} | grep "PATH") == *"RUNPATH"* ]]; then
        errors+="${bin}\n"
    fi
done

if [[ $errors ]]; then
    echo "The following binaries were found with an unexpected RPATH:"
    echo -e "${errors}"
    exit 1
fi
