rm test.vala
touch test.vala
src/gtkamlc test.gtkaml --save-temps --pkg gtk+-2.0 --dump-tree test.vala
cat test.vala
