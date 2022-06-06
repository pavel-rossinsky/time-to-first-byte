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
Being in the `time-to-first-byte` project root folder, run:
```ini
./ttfb.sh {path_to_the_text_file_containing_urls}
```