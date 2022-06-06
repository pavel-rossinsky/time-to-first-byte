The repository contains a bash script that measures Time to First Byte (TTFB) for a single URL or a list of URLs stored in a text file. Excludes failed requests and redirects.

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

## How to run the script
### Option 1
Being in the `time-to-first-byte` project root folder, run:
```
./ttfb.sh -u https://github.com/
```
The script output has the format ``"{http response code} {url} {elapsed time}"``:
```
200 https://github.com/ 0.129872
```

