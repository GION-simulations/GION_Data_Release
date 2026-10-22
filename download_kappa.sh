#!/bin/sh
# Download weak-lensing convergence maps of the GION Quick Data Release.
#
# Usage: sh download_kappa.sh [-j N] ZS_IDX [ZS_IDX ...]
#        sh download_kappa.sh [-j N] all
#
#   ZS_IDX  source-plane index, 95 (z_s ~ 1.5) ... 163 (z_s ~ 0.5); see zs_kappa.txt
#   all     download every map (69 maps of 6.4 GB each)
#   -j N    number of parallel downloads (default: 4)
#
# Maps are saved as lensing_maps/GION_r000_kappa.<ZS_IDX>.fits next to this script.
# Re-running the script skips complete files and resumes partial ones.
#
# Environment variables:
#   GION_BASE_URL  data server (default: https://ipomoea-www.cc.u-tokyo.ac.jp/q75000/GION_QDR)
#   GION_DATA_DIR  where to save the data (default: directory of this script)

set -eu

base_url=${GION_BASE_URL:-https://ipomoea-www.cc.u-tokyo.ac.jp/q75000/GION_QDR}
script_dir=$(cd "$(dirname "$0")" && pwd)
data_dir=${GION_DATA_DIR:-$script_dir}
zs_idx_min=95
zs_idx_max=163
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

# zs_idx and source redshift are listed in zs_kappa.txt
if [ ! -f "$script_dir/zs_kappa.txt" ]; then
    echo "Downloading zs_kappa.txt..."
    curl -fsS --retry 3 -o "$script_dir/zs_kappa.txt" "$base_url/zs_kappa.txt"
fi

if [ "$*" = all ]; then
    set -- $(seq "$zs_idx_min" "$zs_idx_max")
fi

# check all indices before downloading anything
for zs_idx in "$@"; do
    case $zs_idx in
        '' | *[!0-9]*) valid=no ;;
        *) [ "$zs_idx" -ge "$zs_idx_min" ] && [ "$zs_idx" -le "$zs_idx_max" ] && valid=yes || valid=no ;;
    esac
    if [ "$valid" = no ]; then
        echo "Error: invalid zs_idx '$zs_idx' (expected $zs_idx_min ... $zs_idx_max, or 'all')" >&2
        exit 1
    fi
done

out_dir="$data_dir/lensing_maps"
mkdir -p "$out_dir"
echo "Downloading $# convergence map(s) into $out_dir"
status=0
if ! for zs_idx in "$@"; do echo "GION_r000_kappa.$zs_idx.fits"; done \
    | xargs -n 1 -P "$jobs" sh -c "$fetch" sh "$base_url/lensing_maps" "$out_dir" \
    | awk -v label="lensing_maps" "$summarize"; then
    status=1
fi

if [ "$status" -ne 0 ]; then
    echo "Some files failed to download. Re-run the same command to retry;" \
        "complete files are skipped and partial files are resumed." >&2
fi
exit "$status"
