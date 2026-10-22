#!/bin/sh
# Download light-cone halo catalogues of the GION Quick Data Release.
#
# Usage: sh download_halo.sh [-j N] SHELL [SHELL ...]
#        sh download_halo.sh [-j N] all
#
#   SHELL  halo shell directory, S080 (z ~ 1.5) ... S103 (z ~ 0); see z_halo.txt
#   all    download every shell (very large; see README.md for sizes)
#   -j N   number of parallel downloads (default: 4)
#
# Files are saved as lc_halo_props/<SHELL>/halos.<i>.h5 next to this script.
# Re-running the script skips complete files and resumes partial ones.
#
# Environment variables:
#   GION_BASE_URL  data server (default: https://ipomoea-www.cc.u-tokyo.ac.jp/q75000/GION_QDR)
#   GION_DATA_DIR  where to save the data (default: directory of this script)

set -eu

base_url=${GION_BASE_URL:-https://ipomoea-www.cc.u-tokyo.ac.jp/q75000/GION_QDR}
script_dir=$(cd "$(dirname "$0")" && pwd)
data_dir=${GION_DATA_DIR:-$script_dir}
manifest="$script_dir/halo_indices_ranges.txt"
jobs=4

usage() {
    # print the header comment of this script
    sed -n '2,/^$/s/^# \{0,1\}//p' "$0"
    exit "$1"
}

# Download one file; run by xargs as: sh -c "$fetch" sh URL_DIR OUT_DIR FILENAME
# Prints "downloaded", "skipped" (already complete) or "FAILED" with the file path.
fetch='
url="$1/$3" out="$2/$3"
before=-1
[ -f "$out" ] && before=$(($(wc -c < "$out")))
if curl -fsS --retry 3 --retry-delay 5 -C - -o "$out" "$url"; then
    if [ "$before" -eq $(($(wc -c < "$out"))) ]; then
        echo "skipped    $out"
    else
        echo "downloaded $out"
    fi
else
    echo "FAILED     $out"
fi
'

# Echo the lines from fetch and print a summary; fails if any download failed.
summarize='
{ print; fflush(); n[$1]++ }
END {
    printf "%s: %d downloaded, %d skipped, %d failed\n", label, n["downloaded"], n["skipped"], n["FAILED"]
    exit (n["FAILED"] > 0)
}
'

while getopts j:h opt; do
    case $opt in
        j) jobs=$OPTARG ;;
        h) usage 0 ;;
        *) usage 1 >&2 ;;
    esac
done
shift $((OPTIND - 1))
[ $# -gt 0 ] || usage 1 >&2

case $jobs in
    '' | *[!0-9]* | 0) echo "Error: -j expects a positive integer, got '$jobs'" >&2; exit 1 ;;
esac

if [ ! -f "$manifest" ]; then
    echo "Downloading halo_indices_ranges.txt..."
    curl -fsS --retry 3 -o "$manifest" "$base_url/halo_indices_ranges.txt"
fi

if [ "$*" = all ]; then
    set -- $(awk '{print $1}' "$manifest")
fi

# check all shell names before downloading anything
for halodir in "$@"; do
    if ! awk -v d="$halodir" '$1 == d {found = 1} END {exit !found}' "$manifest"; then
        echo "Error: unknown halo shell '$halodir' (expected S080 ... S103, or 'all')" >&2
        exit 1
    fi
done

status=0
for halodir in "$@"; do
    max_halo_idx=$(awk -v d="$halodir" '$1 == d {print $3}' "$manifest")
    out_dir="$data_dir/lc_halo_props/$halodir"
    mkdir -p "$out_dir"
    echo "Downloading $halodir ($((max_halo_idx + 1)) files) into $out_dir"
    if ! seq 0 "$max_halo_idx" | sed 's/.*/halos.&.h5/' \
        | xargs -n 1 -P "$jobs" sh -c "$fetch" sh "$base_url/lc_halo_props/$halodir" "$out_dir" \
        | awk -v label="$halodir" "$summarize"; then
        status=1
    fi
done

if [ "$status" -ne 0 ]; then
    echo "Some files failed to download. Re-run the same command to retry;" \
        "complete files are skipped and partial files are resumed." >&2
fi
exit "$status"
