#!/bin/sh -eu
read initjmp <<- eof
	$(tail -c2 "$1" | od -An -tu2 --endian=little)
eof
if [ $initjmp -ne 3 ]; then
	printf '*** Bad initial jump (%d bytes) ***\n' $initjmp >&2
	exit 1
fi
truncate -s-2 "$1"
