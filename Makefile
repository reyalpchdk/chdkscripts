SCRIPTS=rawopint fixedint contae
DISTZIPS=$(foreach script,$(SCRIPTS),$(script).zip)

.PHONY: clean allscript allzip $(SCRIPTS) $(DISTZIPS)


allscript: $(SCRIPTS)

allzip: $(DISTZIPS)

$(SCRIPTS):
	$(MAKE) -C ./src/$@ script

$(DISTZIPS):
	$(MAKE) -C ./src/$(patsubst %.zip,%,$@) dist

clean:
	@for i in $(SCRIPTS); do \
		$(MAKE) -C ./src/$$i clean || exit 1; \
	done

clean-built:
	@for i in $(SCRIPTS); do \
		$(MAKE) -C ./src/$$i clean-built || exit 1; \
	done

clean-dist:
	@for i in $(SCRIPTS); do \
		$(MAKE) -C ./src/$$i clean-dist || exit 1; \
	done
