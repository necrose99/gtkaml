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
	gtkamlmarkuptag.vala \
	gtkamlmarkupclass.vala \
	gtkamlmarkupsubtag.vala \
	gtkamlunresolvedmarkupsubtag.vala \
	gtkamlmarkupmember.vala \
	gtkamlmarkupnamespace.vala \
	gtkamlmarkupimplicits.vala \
	gtkamlimplicitsstore.vala

libgtkaml_la_SOURCES = \
	libgtkaml.stamp \
	$(libgtkaml_la_VALASOURCES:.vala=.c) \
	$(libgtkaml_la_VALASOURCES:.vala=.h)

libgtkaml.stamp: $(libgtkaml_la_VALASOURCES)
	$(VALAC) -C $(VALAFLAGS) -H gtkaml.h --library gtkaml --pkg glib-2.0 --pkg vala-1.0 $^
	touch $@

EXTRA_DIST = $(libgtkaml_la_VALASOURCES)

