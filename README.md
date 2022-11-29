The repository contains a bash script that measures Time to First Byte (TTFB), Server Time, and Network Latency for a list of URLs stored in a text file using `curl`. Excludes failed requests and redirects.

The ttfb.sh script uses curl for measuring the time.
An article to read explaining the concept https://blog.cloudflare.com/a-question-of-timing/


```
curl -w \
    "time_namelookup: %{time_namelookup}, \
     time_connect: %{time_connect}, \
     time_appconnect: %{time_appconnect}, \
     time_redirect: %{time_redirect}, \
     time_pretransfer: %{time_pretransfer}, \
     time_starttransfer: %{time_starttransfer}\n" \
-o /dev/null -s "https://www.google.com"
```

## Sample output
```
time-to-first-byte % ./ttfb.sh -f sample_urls.txt -r

"Counter" "HTTP Code" "URL" "TTFB (ms)" "Server Time minus Latency (ms)" "Latency (ms)"

1 200 https://www.amazon.de/ 158.67 76.72 22.54
2 200 https://en.zalando.de/ 170.91 62.04 21.84
3 301 https://facebook.com/ -
4 200 https://stackoverflow.com/ 215.93 109.69 22.78
5 301 https://google.de/ -
6 200 https://github.com/ 110.85 8.19 27.48
7 200 https://stackoverflow.com/ 211.28 107.90 21.40

Pages visited / evaluated / skipped:   7 / 5 / 2

Total time elapsed:                  0.87 s
Avg TTFB:                            173.53 ms
Avg server time with latency:        96.12 ms
Avg network latency:                 23.21 ms
Avg server time minus latency:       72.91 ms
Avg server time minus latency*2:     49.70 ms
```

## Technical prerequisites
- curl
- Git
- Docker (optionally)

## Getting started
Run the commands one by one to run the script:
```
git clone git@github.com:pavel-rossinsky/time-to-first-byte.git
cd time-to-first-byte
./ttfb.sh -f sample_urls.txt
```
To see the help text:
```
./ttfb.sh -h
```
