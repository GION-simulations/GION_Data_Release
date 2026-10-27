#!/bin/sh
# Download Sunyaev-Zel'dovich maps of the GION Quick Data Release.
#
# Usage: sh download_sz.sh [-j N] MAP [MAP ...]
#        sh download_sz.sh [-j N] all
#
#   MAP   tsz (thermal SZ, GNFW gas model) or ksz (kinetic SZ)
#   all   download both maps (2 maps of 6.4 GB each)
#   -j N  number of parallel downloads (default: 4)
#
# Maps are saved as SZ_maps/GION_r000_tSZ_GNFW_nres13.fits and
# SZ_maps/GION_r000_kSZ.fits next to this script.
# Re-running the script skips complete files and resumes partial ones.
#
# Environment variables:
#   GION_BASE_URL  data server (default: https://ipomoea-www.cc.u-tokyo.ac.jp/q75000/GION_QDR)
#   GION_DATA_DIR  where to save the data (default: directory of this script)

set -eu

base_url=${GION_BASE_URL:-https://ipomoea-www.cc.u-tokyo.ac.jp/q75000/GION_QDR}
script_dir=$(cd "$(dirname "$0")" && pwd)
data_dir=${GION_DATA_DIR:-$script_dir}
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

# map name -> file name
sz_file() {
    case $1 in
        tsz) echo "GION_r000_tSZ_GNFW_nres13.fits" ;;
        ksz) echo "GION_r000_kSZ.fits" ;;
    esac
}

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

if [ "$*" = all ]; then
    set -- tsz ksz
fi

# check all map names before downloading anything
for map in "$@"; do
    case $map in
        tsz | ksz) ;;
        *) echo "Error: unknown SZ map '$map' (expected tsz, ksz, or 'all')" >&2; exit 1 ;;
    esac
done

out_dir="$data_dir/SZ_maps"
mkdir -p "$out_dir"
echo "Downloading SZ map(s) $* into $out_dir"
status=0
if ! for map in "$@"; do sz_file "$map"; done | sort -u \
    | xargs -n 1 -P "$jobs" sh -c "$fetch" sh "$base_url/SZ_maps" "$out_dir" \
    | awk -v label="SZ_maps" "$summarize"; then
    status=1
fi

if [ "$status" -ne 0 ]; then
    echo "Some files failed to download. Re-run the same command to retry;" \
        "complete files are skipped and partial files are resumed." >&2
fi
exit "$status"
