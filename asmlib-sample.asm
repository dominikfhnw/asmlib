%if 0
# polyglot shellscript/nasm file. Just run it as a shellscript to assemble
. ./asmlib2/build.sh
%endif

%include "main.mac"		; main library
elf simple			; add simple ELF header, PHDR gets automatically added with "simple"

puts `Hello, world!\n`
exit
