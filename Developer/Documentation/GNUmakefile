include $(GNUSTEP_MAKEFILES)/common.make

after-all::
	@echo ""; \
	echo "  Generating Documentation main page in Developer/Documentation"; \
	echo ""; \
	./create-project-doc-index.sh > index.html;

after-distclean::
	@echo ""; \
	echo "  Removing Documentation main page in Developer/Documentation"; \
	echo ""; \
	rm -f ./index.html

include $(GNUSTEP_MAKEFILES)/aggregate.make
