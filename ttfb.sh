#!/bin/bash
set -eu

# Shows time in seconds to first byte of a url or urls
# Run it by supplying the path to the file containing URLs: /ttfb_runner.sh ../../test_urls.txt
# or like this ./bin/dev/ttfb_runner.sh test_urls.txt from the project root.
# You can limit the number of pages that will be visited by the script by adding a numeric value as the second parameter:
# ./bin/dev/ttfb_runner.sh test_urls.txt 10 - the script will visit not more than 10 URLs.

if [[ ! -f $1 ]]; then
    echo "File '$1' not found"
    exit 1
fi

limit=0
if [[ -n ${2+set} ]]; then
    limit=$2
fi

total_time=0
counter=0
non_200_counter=0
while read -r in; do
    counter=$((counter+1))

    read -r curr_time http_code <<< "$(curl --silent -o /dev/null -w "%{time_starttransfer} %{http_code}\n" "$in")"
    if [[ $http_code != '200' ]]; then
        non_200_counter=$((non_200_counter+1))
        echo $counter "$http_code" "$in" -
        continue
    fi

    total_time=$(awk "BEGIN {print $total_time+$curr_time; exit}")
    average=$(awk "BEGIN {print $total_time/($counter-$non_200_counter); exit}")
    echo $counter "$http_code" "$in" "$curr_time" "$total_time" "$average"

    if [[ $limit -gt 0 && $counter -ge $limit ]]; then
        break
    fi
done < "$1"

echo "Pages visited:   $((counter))"
echo "Pages evaluated: $((counter - non_200_counter))"
echo "Pages skipped:   $non_200_counter"
echo "Time elapsed:    $total_time (s)"
echo "Average TTFB:    $(awk "BEGIN {print $total_time/($counter-$non_200_counter); exit}") (s)"
