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
```

## Examples of using
### For a single URL
Being in the `time-to-first-byte` project root folder, run:
```
./ttfb.sh -u https://github.com/

200 https://github.com/ 0.129872
```
The output of the script has the format
```
"{http response code} {url} {elapsed time}"
```

### For a file containing URLs
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
The output of the script has the format
```
"{request number} {http response code} {url} {current url elapsed time} {total elapsed time} {current average ttfb}"
```


You can overwrite the default user-agent

