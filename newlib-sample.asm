%if 0
# polyglot shellscript/nasm file. Just run it as a shellscript to compile
. ./newlib/build.sh
%endif

%include "main.mac"		; main library
elf simple			; add simple ELF header, PHDR gets automatically added with "simple"

printstr `Hello, world!\n`
exit
