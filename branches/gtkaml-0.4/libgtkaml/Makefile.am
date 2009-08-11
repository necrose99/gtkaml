AM_CPPFLAGS = \
	$(GLIB_CFLAGS) \
	$(VALA_CFLAGS) 

libgtkaml_la_LIBADD = \
	$(GLIB_LIBS) \
	$(VALA_LIBS)

lib_LTLIBRARIES = \
	libgtkaml.la


BUILT_SOURCES = libgtkaml.stamp

libgtkaml_la_VALASOURCES = \
	gtkamlmarkupparser.vala \
	gtkamlmarkupresolver.vala \
	gtkamlmarkupattribute.vala \
	gtkamlsimplemarkupattribute.vala \
	gtkamlcomplexmarkupattribute.vala \
	gtkamlmarkupclass.vala \
	ast/gtkamlmarkuptag.vala \
	ast/gtkamlmarkuproot.vala \
	ast/gtkamlmarkupsubtag.vala \
	ast/gtkamlunresolvedmarkupsubtag.vala \
	ast/gtkamlmarkupmember.vala \
	ast/gtkamlmarkuptemp.vala \
	gtkamlmarkupnamespace.vala \
	gtkamlmarkuphint.vala \
	gtkamlmarkuphintsstore.vala \
	workarounds/gtkamldatatypeparent.vala

libgtkaml_la_SOURCES = \
	libgtkaml.stamp \
	$(libgtkaml_la_VALASOURCES:.vala=.c) \
	$(libgtkaml_la_VALASOURCES:.vala=.h)

libgtkaml.stamp: $(libgtkaml_la_VALASOURCES)
	$(VALAC) -C $(VALAFLAGS) -H gtkaml.h --library gtkaml --pkg glib-2.0 --pkg vala-1.0 $^
	touch $@

EXTRA_DIST = $(libgtkaml_la_VALASOURCES)

