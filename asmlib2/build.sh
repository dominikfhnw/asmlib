#!/bin/bash
set -ue
set -o pipefail

: ${TRACE=0}
: ${VERBOSE=1}
: ${DUMP=-Mintel}
: ${DISAS=1}
: ${OUT=${0%.*}}
: ${LDFLAGS=-Ttext-segment=0x10000 --noinhibit-exec}
: ${M1=elf32}
: ${M2=elf_i386}
: ${LIBRARY=0}

if [ "$VERBOSE" -eq 1 ]; then
	filter(){
		grep -a --color=always -E '|error:'
	}
else
	filter(){
		grep -a -vF ': ... from macro ' | grep -a --color=always -E '|error:'
	}
fi


if [ "$LIBRARY" -ne 0 ]; then
	FULL=1
fi

DIR=${BASH_SOURCE%/*}

build(){
	sed -E 's/:=/_~/' "$0" > "$0.sed"
	SOURCE="$0.sed"
	NASM="nasm -DTRACE=$TRACE -w+all -Werror=label-orphan -g -I $DIR ${EXTRA:-}"
	if [ -n "${FULL-}" ]; then
		FULLBIN="$OUT.full"
		rm -f $OUT $OUT.o $FULLBIN
		$NASM -f "$M1" -o $OUT.o "$SOURCE" "$@" 2>&1 | filter
		{ $NASM -e "$SOURCE" "$@" ||:; } 2>/dev/null | grep -Ev '^(%line|$)' | sed '/:$/s/^/\n/' > preproc.asm
		if [ "$LIBRARY" -eq 0 ]; then
			ld $LDFLAGS -m "$M2" -z noseparate-code $OUT.o -o $OUT
			cp $OUT $FULLBIN
			ls -l $FULLBIN
			sstrip3 $OUT >/dev/null
		else
			OUT="$OUT.o"
		fi
	else
		rm -f $OUT
		$NASM -f bin -o $OUT "$SOURCE" "$@" 2>&1 | filter

		{ $NASM -e "$SOURCE" "$@" ||:; } 2>/dev/null | grep -Ev '^(%line|$)' | sed '/:$/s/^/\n/' > preproc.asm
	fi
}

build "$@"
if [ -n "${POSTBUILD-}" ]; then
	echo "POSTBUILD"
	eval "$POSTBUILD"
fi

ls -l $OUT
chmod +x $OUT

if [ "$DISAS" -eq 1 ]; then
	if [ "$LIBRARY" -ne 0 ]; then
		objdump $DUMP -d $OUT
	elif [ -n "${FULL-}" ]; then
		objdump -j .text $DUMP -d $FULLBIN
	else
		if [ -n "${LINCOM-}" ]; then
			OFF="0x10000"
			START="0x10000"
		else
			OFF=$(  readelf3 -lW $OUT 2>/dev/null | awk '$2~/^0x000/{sub(/...$/,"000",$3); print $3}')
			if [ -z "${START-}" ]; then
				START=$(readelf3 -hW $OUT 2>/dev/null | awk '$1=="Entry"{print $4}')
			fi
		fi
		echo "OFF $OFF START $START"
		objdump $DUMP -b binary -m i386 -D $OUT --adjust-vma="$OFF" --start-address="$START"
	fi
fi

set +e
ls -l $OUT

[ "${NOEXIT-}" ] || exit 0
