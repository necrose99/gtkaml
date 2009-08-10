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
	gtkamlmarkupattributevalue.vala \
	gtkamlmarkuptag.vala \
	gtkamlclass.vala \
	gtkamlmarkupmember.vala

libgtkaml_la_SOURCES = \
	libgtkaml.stamp \
	$(libgtkaml_la_VALASOURCES:.vala=.c) \
	$(libgtkaml_la_VALASOURCES:.vala=.h)

libgtkaml.stamp: $(libgtkaml_la_VALASOURCES)
	$(VALAC) -C --library gtkaml --pkg glib-2.0 --pkg vala-1.0 $^
	touch $@

EXTRA_DIST = $(libgtkaml_la_VALASOURCES)

