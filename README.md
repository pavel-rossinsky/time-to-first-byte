The repository contains a bash script that measures Time to First Byte (TTFB) for a single URL or a list of URLs stored in a text file using `curl`. Excludes failed requests and redirects.

## Technical prerequisites
- Unix-based OS
- Git
- Docker (optionally)

## Getting started
Run the commands one by one:
```
git clone git@github.com:pavel-rossinsky/time-to-first-byte.git
cd time-to-first-byte
./ttfb.sh -f sample_urls.txt
```

## Examples of using
### 1. For a single URL
Being in the `time-to-first-byte` project root folder, run:
```
./ttfb.sh -u https://github.com/

200 https://github.com/ 0.129872
```
The output of the script has the format
```
"{http response code} {url} {elapsed time}"
```

### 2. For a file containing URLs
The output of the script has the format
```
"{request number} {http response code} {url} {current url elapsed time} {total elapsed time} {average ttfb}"
```
#### 2.1. Read all URLs from the file:
```
time-to-first-byte % ./ttfb.sh -f sample_urls.txt

1 200 https://github.com/ 0.112465 0.112465 0.112465
2 200 https://stackoverflow.com/ 0.174784 0.287249 0.143624
3 200 https://www.amazon.de/ 0.196717 0.483966 0.161322
4 301 https://google.de/ -
5 301 https://facebook.com/ -
6 200 https://en.zalando.de/ 0.125332 0.609298 0.152325
7 200 https://stackoverflow.com/ 0.460509 1.06981 0.213962

Pages visited:       7
Pages evaluated:     5
Pages skipped:       2
Total time elapsed:  1.06981 (s)
Average TTFB:        0.213962 (s)

```

#### 2.2. Read the URLs until the limit is reached:
```
time-to-first-byte % ./ttfb.sh -f sample_urls.txt -l 4

1 200 https://github.com/ 0.111217 0.111217 0.111217
2 200 https://stackoverflow.com/ 0.182406 0.293623 0.146812
3 200 https://www.amazon.de/ 0.160168 0.453791 0.151264
4 301 https://google.de/ -

Pages visited:       4
Pages evaluated:     3
Pages skipped:       1
Total time elapsed:  0.453791 (s)
Average TTFB:        0.151264 (s)
```

#### 2.3. An attempt to invalidate the cache by the timestamp to the URL:
```
time-to-first-byte % ./ttfb.sh -f sample_urls.txt -i

1 200 https://github.com/?1654526447 0.162112 0.162112 0.162112
2 200 https://stackoverflow.com/?1654526447 0.199262 0.361374 0.180687
3 200 https://www.amazon.de/?1654526448 0.226197 0.587571 0.195857
4 301 https://google.de/?1654526448 -
5 301 https://facebook.com/?1654526449 -
6 200 https://en.zalando.de/?1654526449 0.181985 0.769556 0.192389
7 200 https://stackoverflow.com/?1654526449 0.192427 0.961983 0.192397

Pages visited:       7
Pages evaluated:     5
Pages skipped:       2
Total time elapsed:  0.961983 (s)
Average TTFB:        0.192397 (s)
```
