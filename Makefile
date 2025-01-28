# Copyright (C) 2003-2025 ITRS Group Ltd. All rights reserved

USER  := root
GROUP := root

OUT_PREFIX=$(shell pwd)/out

MONITORING_PLUGINS = monitoring-plugins-2.2
CHECK_RADIUS_IH = check_radius_ih-1.1

EXTRACTED_DIR = extracted

out/plugins out/perl $(EXTRACTED_DIR):
	mkdir -p $@

.PHONY: monitoring-plugins-extract
monitoring-plugins-extract: $(EXTRACTED_DIR)
	mkdir -p extracted
	tar -vxf vendor/$(MONITORING_PLUGINS).tar.gz -C $(EXTRACTED_DIR)

.PHONY: monitoring-plugins-patch
MP_PATCH_DIR=../../patches/monitoring-plugins
MP_EXTRACTED=$(EXTRACTED_DIR)/$(MONITORING_PLUGINS)
monitoring-plugins-patch: monitoring-plugins-extract
	cd $(MP_EXTRACTED) && patch -p1 < $(MP_PATCH_DIR)/check_file_age.diff
	cd $(MP_EXTRACTED) && patch -p1 < $(MP_PATCH_DIR)/check_disk_smb.diff
	cd $(MP_EXTRACTED) && patch -p1 < $(MP_PATCH_DIR)/nagiosplug_check_snmp_override_perfstat_units.patch
	cd $(MP_EXTRACTED) && patch -p1 < $(MP_PATCH_DIR)/nagiosplug_check_procs_add_negate_ereg.patch
	cd $(MP_EXTRACTED) && patch -p1 < $(MP_PATCH_DIR)/nagiosplug_hidden_passwords.patch
	cd $(MP_EXTRACTED) && patch -p1 < $(MP_PATCH_DIR)/nagiosplug_hidden_args_scripts.patch
	cd $(MP_EXTRACTED) && patch -p1 < $(MP_PATCH_DIR)/nagiosplug_negate_validate_check_path.patch

	# Add in JSON perl module for use by check_docker
	cp vendor/JSON-2.90.tar.gz $(MP_EXTRACTED)/perlmods
	cd $(MP_EXTRACTED) && patch -p1 < $(MP_PATCH_DIR)/moniplug_json_perl_module.patch

.PHONY: monitoring-plugins-build
MP_EXTRACTED=$(EXTRACTED_DIR)/$(MONITORING_PLUGINS)

monitoring-plugins-build:
monitoring-plugins-build: out/plugins monitoring-plugins-extract monitoring-plugins-patch
	cd $(MP_EXTRACTED) && PATH="/usr/bin:/usr/sbin:$$PATH" ./configure \
		--prefix=$(OUT_PREFIX) \
		--with-mysql \
		--with-nagios-user=$(USER) \
		--with-nagios-group=$(GROUP) \
		--with-rpcinfo-command=/usr/sbin/rpcinfo \
		--enable-perl-modules \
		--without-world-permissions \
		--localstatedir=$(OUT_PREFIX)/var/plugins \
		--enable-extra-opts=no
	$(MAKE) -C $(MP_EXTRACTED)
	$(MAKE) -C $(MP_EXTRACTED) install-strip prefix=$(OUT_PREFIX)/perl libexecdir=$(OUT_PREFIX)/plugins

	find $(OUT_PREFIX) -type f -name .packlist -print -delete
	find $(MP_EXTRACTED)/plugins -type l -exec chown -h $(USER):$(GROUP) {} \;
	find $(MP_EXTRACTED)/plugins -type f -executable -print -exec mv -t $< {} +
	find $(MP_EXTRACTED)/plugins-root -type f -executable -print -exec mv -t $< {} +
	find $(MP_EXTRACTED)/plugins-scripts -type f -executable -print -exec mv -t $< {} +

	# Remove urlize plugin due to security vulnerability
	$(RM) $</urlize
	# Delete any unit test files
	$(RM) $</*.t
	# Delete any plugin templates
	$(RM) $</check_*.pl* $</check_*.sh*

# Check Radius
.PHONY: check-radius-extract
check-radius-extract: $(EXTRACTED_DIR)
	tar -xf vendor/$(CHECK_RADIUS_IH).tgz -C $(EXTRACTED_DIR)

.PHONY: check-radius-patch
CR_PATCH_DIR=../../patches/check-radius
CR_EXTRACTED=$(EXTRACTED_DIR)/$(CHECK_RADIUS_IH)
check-radius-patch: check-radius-extract
	cd $(CR_EXTRACTED) && patch -p1 < $(CR_PATCH_DIR)/makefile.patch
	cd $(CR_EXTRACTED) && patch -p1 < $(CR_PATCH_DIR)/lucid_fixes.patch
	cd $(CR_EXTRACTED) && patch -p1 < $(CR_PATCH_DIR)/hidden_passwords.patch

.PHONY: check-radius-build
CR_EXTRACTED=$(EXTRACTED_DIR)/$(CHECK_RADIUS_IH)
check-radius-build: out/plugins check-radius-patch
	cd $(CR_EXTRACTED) && ./configure
	cd $(CR_EXTRACTED) && make
	mv $(CR_EXTRACTED)/check_radius_ih $</

.PHONY: custom-plugins
custom-plugins: out/plugins
	cp vendor/custom-plugins/* $</

.PHONY: build
build: check-radius-build monitoring-plugins-build custom-plugins

.PHONY: verify
verify:	test lint

.PHONY: lint
lint:
	@echo "Nothing to do!"

.PHONY: test
test:
	@ret=0; \
	for file in ./tests/test_*.sh; do printf "\nTesting: $$file\n" && $$file || ret=1 ; done; \
	exit $$ret

clean:
	$(RM) -r extracted out
