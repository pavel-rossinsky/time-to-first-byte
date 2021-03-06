#!/bin/bash
set -eu

function help() {
    tput setaf 2
    echo "Usage ./ttfb.sh -u <url> [-a] [-i] | -f <file> [-a] [-l] [-i] | -h"

    tput setaf 3
    echo "Options:"
    echo -e "-u \t Single URL. Overwrites the -f option."
    echo -e "-f \t Path to the file with URLs."
    echo -e "-l \t Limit of the URLs to read from the file."
    echo -e "-a \t Overwrites the default user-agent."
    echo -e "-i \t [Flag] Attempt to invalidate cache by adding a timestamp to the URLs."
    echo -e "-h \t [Flag] Help."

    exit 0
}

if [[ ! $* =~ ^\-.+ ]]; then
    help
fi

while getopts "f:u:l:a:ih" opt; do
    case "$opt" in
    f) file=${OPTARG} ;;
    u) url=${OPTARG} ;;
    a) user_agent="${OPTARG}" ;;
    l) limit=${OPTARG} ;;
    i) invalidate_cache=1 ;;
    h) help ;;
    *) help ;;
    esac
done

if [[ -z ${user_agent+set} ]]; then
    user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.0.0 Safari/537.36"
fi

if [[ -z ${invalidate_cache+set} ]]; then
    invalidate_cache=0
fi

function send_request() {
    curl -H "user-agent: $2" \
        --silent \
        -o /dev/null \
        -w "%{time_starttransfer} %{http_code}\n" \
        "$1"
}

function prepare_url() {
    url=$1

    if [[ $2 -gt 0 ]]; then
        if [[ "$url" == *"?"* ]]; then
            url="$url&$(date +%s)"
        else
            url="$url?$(date +%s)"
        fi
    fi

    echo "$url"
}

if [[ -n ${url+set} ]]; then
    url="$(prepare_url "$url" $invalidate_cache)"
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
printf "\n"
while read -r in || [ -n "$in" ]; do
    counter=$((counter + 1))

    in="$(prepare_url "$in" $invalidate_cache)"

    read -r curr_time http_code <<<"$(send_request "$in" "$user_agent")"
    if [[ $http_code != '200' ]]; then
        non_200_counter=$((non_200_counter + 1))
        echo $counter "$http_code" "$in" -
    else
        total_time=$(awk "BEGIN {print $total_time+$curr_time; exit}")
        average=$(awk "BEGIN {print $total_time/($counter-$non_200_counter); exit}")
        echo $counter "$http_code" "$in" "$curr_time" "$total_time" "$average"
    fi

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
