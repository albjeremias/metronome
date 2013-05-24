
include config.unix

BIN = $(DESTDIR)$(PREFIX)/bin
CONFIG = $(DESTDIR)$(SYSCONFDIR)
MODULES = $(DESTDIR)$(PREFIX)/lib/metronome/modules
SOURCE = $(DESTDIR)$(PREFIX)/lib/metronome
DATA = $(DESTDIR)$(DATADIR)

INSTALLEDSOURCE = $(PREFIX)/lib/metronome
INSTALLEDCONFIG = $(SYSCONFDIR)
INSTALLEDMODULES = $(PREFIX)/lib/metronome/modules
INSTALLEDDATA = $(DATADIR)

.PHONY: all clean install uninstall

all: metronome.install metronomectl.install metronome.cfg.lua.install metronome.version
	$(MAKE) -C util-src install

install: metronome.install metronomectl.install util/encodings.so util/encodings.so util/pposix.so util/signal.so
	install -d $(BIN) $(CONFIG) $(MODULES) $(SOURCE)
	install -m750 -d $(DATA)
	install -d $(CONFIG)/certs
	install -d $(SOURCE)/core $(SOURCE)/net $(SOURCE)/util
	install -m755 ./metronome.install $(BIN)/metronome
	install -m755 ./metronomectl.install $(BIN)/metronomectl
	install -m644 core/* $(SOURCE)/core
	install -m644 net/*.lua $(SOURCE)/net
	install -d $(SOURCE)/net/http
	install -m644 net/http/*.lua $(SOURCE)/net/http
	install -m644 util/*.lua $(SOURCE)/util
	install -m644 util/*.so $(SOURCE)/util
	install -d $(SOURCE)/util/sasl
	install -m644 util/sasl/* $(SOURCE)/util/sasl
	umask 0022 && cp -r plugins/* $(MODULES)
	install -m644 certs/* $(CONFIG)/certs
	test -e $(CONFIG)/metronome.cfg.lua || install -m644 metronome.cfg.lua.install $(CONFIG)/metronome.cfg.lua
	test -e metronome.version && install metronome.version $(SOURCE)/metronome.version || true
	$(MAKE) install -C util-src

clean:
	rm -f metronome.install
	rm -f metronomectl.install
	rm -f metronome.cfg.lua.install
	rm -f metronome.version
	$(MAKE) clean -C util-src

uninstall:
	rm -rf $(SOURCE)
	rm -rf $(MODULES)
	rm -f $(BIN)/bin/metronome
	rm -f $(BIN)/bin/metronomectl

util/%.so:
	$(MAKE) install -C util-src

%.install: %
	sed "s|^CFG_SOURCEDIR=.*;$$|CFG_SOURCEDIR='$(INSTALLEDSOURCE)';|; \
		s|^CFG_CONFIGDIR=.*;$$|CFG_CONFIGDIR='$(INSTALLEDCONFIG)';|; \
		s|^CFG_DATADIR=.*;$$|CFG_DATADIR='$(INSTALLEDDATA)';|; \
		s|^CFG_PLUGINDIR=.*;$$|CFG_PLUGINDIR='$(INSTALLEDMODULES)/';|;" < $^ > $@

metronome.cfg.lua.install: metronome.cfg.lua.dist
	sed 's|certs/|$(INSTALLEDCONFIG)/certs/|' $^ > $@

metronome.version: $(wildcard metronome.release)
	test -f metronome.release && \
		cp metronome.release $@ || true
