
AM_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(VALA_CFLAGS) \
	$(LIBXML2_CFLAGS) \
	-I$(top_srcdir)/libgtkaml

bin_PROGRAMS = gtkamlc

BUILT_SOURCES = gtkamlc.stamp

gtkamlc_VALASOURCES = gtkamlcompiler.vala

gtkamlc_SOURCES = \
	gtkamlc.stamp \
	$(gtkamlc_VALASOURCES:.vala=.c) 

gtkamlc.stamp : $(gtkamlc_VALASOURCES)
	$(VALAC) -C $(VALAFLAGS) --vapidir ../libgtkaml --pkg gtkaml-1.0 --pkg libxml-2.0 --pkg vala-1.0 --pkg glib-2.0 $^
	touch $@

gtkamlc_LDADD = \
	$(GLIB_LIBS) \
	$(VALA_LIBS) \
	$(LIBXML2_LIBS) \
	$(top_srcdir)/libgtkaml/libgtkaml.la

EXTRA_DIST = $(gtkamlc_VALASOURCES)

