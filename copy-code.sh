#!/bin/sh -eu
read dst dstlen <<- eof
	$(tail -c4 "$1" | od -An -tu2 --endian=little)
eof
srclen=$(stat -c%s "$1")
srclen=$(($srclen - $2 - 4 + ${3-0}))
if [ $srclen -gt $dstlen ]; then \
	printf '*** Too much code (%d > %d) ***\n' $srclen $dstlen >&2
	exit 1
fi
dd if="$1" of="$1" bs=1 skip="$2" seek=$dst count=$srclen conv=notrunc
truncate -s-4 "$1"
