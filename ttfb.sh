#!/bin/bash
set -eu

function help() {
    tput setaf 2
    echo "Usage ./ttfb.sh -f <file> [-a] [-l] [-i] [-r] | -h"

    tput setaf 3
    echo "Options:"
    echo -e "-f \t Path to the file with URLs."
    echo -e "-a \t Overwrites the default user-agent."
    echo -e "-l \t Limit number of URLs to read from the file."
    echo -e "-i \t [Flag] Attempt to invalidate cache by adding a timestamp to the URLs."
    echo -e "-r \t [Flag] Reads random rows from the file."
    echo -e "-h \t [Flag] Help."

    exit 0
}

if [[ ! $* =~ ^\-.+ ]]; then
    help
fi

while getopts "f:l:a::rih" opt; do
    case "$opt" in
    f) file=${OPTARG} ;;
    a) user_agent="${OPTARG}" ;;
    l) limit=${OPTARG} ;;
    i) invalidate_cache=1 ;;
    r) random=1 ;;
    h) help ;;
    *) help ;;
    esac
done

if [[ ! -f $file ]]; then
    echo "File '$file' not found"
    exit 1
fi

if [[ -z ${limit+set} ]]; then
    limit=$(wc -l < "$file")
else
    lines_in_file=$(wc -l < "$file")
    if [[ $limit -gt $lines_in_file ]]; then
        printf "The limit is set to its max %d instead of %d \n" "$lines_in_file" "$limit"
        limit=$lines_in_file
    fi
fi

if [[ -z ${user_agent+set} ]]; then
    user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.0.0 Safari/537.36"
fi

if [[ -z ${invalidate_cache+set} ]]; then
    invalidate_cache=0
fi

if [[ -z ${random+set} ]]; then
    random=0
fi

function send_request() {
    curl -H "user-agent: $2" \
        --silent \
        -o /dev/null \
        -w "%{time_starttransfer} %{http_code} %{time_pretransfer} %{time_connect} %{time_namelookup}\n" \
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

time_total=0
server_time_total=0
latency_time_total=0
visited_counter=0
non_200_counter=0

printf "\n"

function evaluate_url() {
    [ $visited_counter -eq 0 ] &&
    printf '"%s" "%s" "%s" "%s" "%s" "%s"\n' "Counter" "HTTP Code" "URL" "TTFB (ms)" "Server Time minus Latency (ms)" "Latency (ms)"
    
    ((visited_counter+=1))

    url="$(prepare_url "$1" $invalidate_cache)"

    read -r time_starttransfer http_code time_pretransfer time_connect time_namelookup <<<"$(send_request "$url" "$user_agent")"
    if [[ $http_code != '200' ]]; then
        non_200_counter=$((non_200_counter + 1))
        echo "$visited_counter" "$http_code" "$url" -
    else
        server_time=$(awk "BEGIN {print $time_starttransfer-$time_pretransfer; exit}")
        server_time_total=$(awk "BEGIN {print $server_time_total+$server_time; exit}")
        latency_time=$(awk "BEGIN {print $time_connect-$time_namelookup; exit}")
        latency_time_total=$(awk "BEGIN {print $latency_time_total+$latency_time; exit}")
        time_total=$(awk "BEGIN {print $time_total+$time_starttransfer; exit}")
        server_time_average=$(awk "BEGIN {print $server_time_total/($visited_counter-$non_200_counter); exit}")
        
        latency_time_ms="$(awk "BEGIN {print $latency_time * 1000; exit}")"
        time_starttransfer_ms="$(awk "BEGIN {print $time_starttransfer * 1000; exit}")"
        server_time_no_latency_ms=$(awk "BEGIN {print ($server_time-$latency_time) * 1000; exit}")
        
        printf "%d %d %s %.2f %.2f %.2f\n" "$visited_counter" "$http_code" "$url" "$time_starttransfer_ms" "$server_time_no_latency_ms" "$latency_time_ms"
    fi
}

if [[ $random == 1 ]]; then
    random_rows=()

    while IFS= read -r row ; do random_rows+=("$row"); done <<< "$(
        awk -v loop="$limit" -v range="$(wc -l < "$file")" 'BEGIN {
            srand()
            do {
                numb = 1 + int(rand() * range)
                if (!(numb in prev)) {
                   print numb
                   prev[numb] = 1
                   count++
                }
            } while (count<loop)
        }'
    )"

    for row in "${random_rows[@]}"
    do
        in=$(awk "NR==$row{ print; exit }" "$file")
        evaluate_url "$in"
    done
else
    while read -r in || [ -n "$in" ]; do
        [ -z "$in" ] && continue
        
        evaluate_url "$in"

        if [[ $limit -gt 0 && $visited_counter -ge $limit ]]; then
            break
        fi
    done <"$file"
fi

printf "\n"

pages_evaluated=$(awk "BEGIN {print $visited_counter-$non_200_counter; exit}")

printf "Pages visited / evaluated / skipped:   %d / %d / %d\n\n" "$visited_counter" "$((visited_counter - non_200_counter))" "$non_200_counter"
printf "Total time elapsed:                  %.2f s\n" "$time_total"

if [[ $pages_evaluated -gt 0 ]]; then
    latency_time_average=$(awk "BEGIN {print $latency_time_total/$pages_evaluated; exit}")
    server_time_average=$(awk "BEGIN {print $server_time_total/$pages_evaluated; exit}")
    
    printf "Avg TTFB:                            %.2f ms\n" "$(awk "BEGIN {print ($time_total/$pages_evaluated) * 1000; exit}")"
    printf "Avg server time with latency:        %.2f ms\n" "$(awk "BEGIN {print $server_time_average * 1000; exit}")"
    printf "Avg network latency:                 %.2f ms\n" "$(awk "BEGIN {print $latency_time_average * 1000; exit}")"
    printf "Avg server time minus latency:       %.2f ms\n" "$(awk "BEGIN {print ($server_time_average - $latency_time_average) * 1000; exit}")"
    printf "Avg server time minus latency*2:     %.2f ms\n" "$(awk "BEGIN {print ($server_time_average - $latency_time_average*2) * 1000; exit}")"
fi

printf "\n"
