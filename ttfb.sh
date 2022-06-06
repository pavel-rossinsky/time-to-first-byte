#!/bin/bash
set -eu

while getopts "f:u:l:a:" p; do
    case "$p" in
    f) file=${OPTARG} ;;
    u) url=${OPTARG} ;;
    a) user_agent="user-agent: ${OPTARG}" ;;
    l) limit=${OPTARG} ;;
    *)
        echo "usage: $0 [-f] [-u] [-l] [-a]" >&2
        exit 1
        ;;
    esac
done

if [[ -z ${user_agent+set} ]]; then
    user_agent="user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.0.0 Safari/537.36"
fi

send_request() {
    curl -H "$2" \
        --silent \
        -o /dev/null \
        -w "%{time_starttransfer} %{http_code}\n" \
        "$1"
}

if [[ -n ${url+set} ]]; then
    read -r curr_time http_code <<<"$(send_request "$url" "$user_agent")"
    echo "$http_code" "$url" "$curr_time"

    exit 0
fi

if [[ -z ${limit+set} ]]; then
    limit=0
fi

if [[ ! -f $file ]]; then
    echo "File '$file' not found"
    exit 1
fi

total_time=0
counter=0
non_200_counter=0
while read -r in || [ -n "$in" ]; do
    counter=$((counter + 1))

    read -r curr_time http_code <<<"$(send_request "$in" "$user_agent")"
    if [[ $http_code != '200' ]]; then
        non_200_counter=$((non_200_counter + 1))
        echo $counter "$http_code" "$in" -
        continue
    fi

    total_time=$(awk "BEGIN {print $total_time+$curr_time; exit}")
    average=$(awk "BEGIN {print $total_time/($counter-$non_200_counter); exit}")
    echo $counter "$http_code" "$in" "$curr_time" "$total_time" "$average"

    if [[ $limit -gt 0 && $counter -ge $limit ]]; then
        break
    fi
done <"$file"

printf "\n"
echo "Pages visited:       $((counter))"
echo "Pages evaluated:     $((counter - non_200_counter))"
echo "Pages skipped:       $non_200_counter"
echo "Total time elapsed:  $total_time (s)"
echo "Average TTFB:        $(awk "BEGIN {print $total_time/($counter-$non_200_counter); exit}") (s)"
