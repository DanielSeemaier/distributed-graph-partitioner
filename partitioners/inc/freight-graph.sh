#!/bin/bash

. "$script_pwd/../partitioners/inc/git.sh"

Fetch() {
    local -n fetch_args=$1

    if (( ${fetch_args[install_disk_driver]} )); then 
        FetchDiskDriver fetch_args
    fi
    if (( ${fetch_args[install_kagen_driver]} )); then 
        echo "KaGen support is not implemented for FREIGHT-Graph"
        exit 1
    fi
}

FetchDiskDriver() {
    local -n fetch_disk_driver_args=$1
    GenericGitFetch fetch_disk_driver_args "$FREIGHT_REPOSITORY_URL" "disk_driver_src"
}

Install() {
    local -n install_args=$1
    
    if (( ${install_args[install_disk_driver]} )); then 
        InstallDiskDriver install_args
    fi
    if (( ${install_args[install_kagen_driver]} )); then 
        echo "KaGen support is not implemented for FREIGHT-Graph"
        exit 1
    fi
}

InstallDiskDriver() {
    local -n install_disk_driver_args=$1

    src_dir="${install_disk_driver_args[disk_driver_src]}"

    echo -e "Build algorithm '$ALGO_COLOR${install_disk_driver_args[algorithm]}$NO_COLOR' in directory '$src_dir'"
    echo "  - System-specific CMake options: $CUSTOM_CMAKE_FLAGS"
    echo -e "  - Algorithm-specific CMake options: $ARGS_COLOR${install_disk_driver_args[algorithm_build_options]}$NO_COLOR"
    echo ""

    Prefixed cmake -S "$src_dir/code_for_graphs" \
        -B "$src_dir/build" \
        -DCMAKE_BUILD_TYPE=Release \
        $CUSTOM_CMAKE_FLAGS \
        ${install_disk_driver_args[algorithm_build_options]}
    Prefixed cmake --build "$src_dir/build" --target freight_graphs --parallel
    Prefixed cp "$src_dir/build/freight_graphs" "${install_disk_driver_args[disk_driver_bin]}"
}

InvokeFromDisk() {
    local -n invoke_from_disk_args=$1
    
    graph="${invoke_from_disk_args[graph]}"
    [[ -f "$graph.graph" ]] && graph="$graph.graph"
    [[ -f "$graph.metis" ]] && graph="$graph.metis"

    if [[ "${invoke_from_disk_args[print_partitioner]}" == "1" ]]; then 
        >&2 echo -e "Generating calls for algorithm '$ALGO_COLOR${invoke_from_disk_args[algorithm]}$NO_COLOR', from disk, via the binary:"
        >&2 echo "  - Binary: ${invoke_from_disk_args[bin]}"
        >&2 echo "  - Generated arguments: "
        >&2 echo -e "      $ARGS_COLOR$graph$NO_COLOR"
        >&2 echo -e "      --k=$ARGS_COLOR${invoke_from_disk_args[k]}$NO_COLOR"
        >&2 echo -e "      --imbalance=$ARGS_COLOR${invoke_from_disk_args[epsilon]}$NO_COLOR"
        >&2 echo -e "      --seed=$ARGS_COLOR${invoke_from_disk_args[seed]}$NO_COLOR"
        >&2 echo -e "      --suppress_file_output"
        >&2 echo -e "  - Specified arguments: $ARGS_COLOR${invoke_from_disk_args[algorithm_arguments]}$NO_COLOR"
        >&2 echo "[...]"
        >&2 echo ""
    fi

    if [[ -f "$graph" ]]; then
        echo -n "${invoke_from_disk_args[bin]} "
        echo -n "$graph "
        echo -n "--k=${invoke_from_disk_args[k]} "
        echo -n "--imbalance=${invoke_from_disk_args[epsilon]} "
        echo -n "--seed=${invoke_from_disk_args[seed]} "
        echo -n "--suppress_file_output "
        echo -n "${invoke_from_disk_args[algorithm_arguments]}"
        echo ""
    else 
        >&2 echo "Warning: Graph $graph does not exist; skipping instance"
        return 1
    fi
}

ReportVersion() {
    GenericGitReportVersion $1
}
