REPOS := hanke/nibabel.git nipy/nipy.git fperez/nitime.git Garyfallidis/dipy.git miketrumpis/xipy.git
PROJECTS := $(shell echo $(REPOS) | sed -e 's,\S*/\(\S*\).git,\1,g')

PYTHON ?= python
INSTALLDIR=$(CURDIR)/install

RUN=$(CURDIR)/bin/runc
export DRY VERBOSE
# TODO: python version and installation path
PYTHONPATH := $(PYTHONPATH):$(INSTALLDIR)/lib/python2.6/site-packages/
export PYTHONPATH

all: install test

all-%:
	@echo I: $* all subprojects
	@$(MAKE) $(foreach prj, $(PROJECTS), $*-$(prj))

# Rules for specific actions
clean-%:
	@cd $*; $(RUN) "clean $*" $(PYTHON) setup.py clean

build-%:
	@cd $*; $(RUN) "build $*" $(PYTHON) setup.py build

install-%:
	@cd $*; $(RUN) "install $*" $(PYTHON) setup.py install --prefix=$(INSTALLDIR)

test-%:
# To make sure things up-to-date
	@[ -z $$VERBOSE ] ||  echo "PYTHONPATH=$$PYTHONPATH"
	@$(RUN) "Assuring uptodate install of $*" $(MAKE) install-$*
	@cd $(INSTALLDIR) && $(RUN) "Testing $*" nosetests -q $*

# Dependencies:
install-nipy: install-nibabel
install-dipy: install-nibabel install-nipy
install-nitime: install-nipy
install-xipy: install-nipy install-dipy

# Shortcuts
clean: all-clean
	# nipy(?) leaves things behind
	-rm failed.nii.gz
	# nitime and xipy still have build
	rm -rf $(foreach prj, $(PROJECTS), $(prj)/build)
	# DiPy doesn't remove generated .c files upon clean
	find dipy -iname *.c -delete

dist-clean: clean
	rm -rf install

build: all-build
install: all-install
test: all-test

# To oversee repositories
status:
	: I: Current repository
	git status
	: I: Submodules
	git submodule status

describe:
	: I: Main module version:
	@git describe
	: I: Dependent modules
	@git submodule foreach 'git describe || :'

# Invoke ipython in current "environment"
ipython:
	ipython
shell:
	$(SHELL)

# Initial creation
init:
	git init
	for r in $(REPOS); do git submodule add git://github.com/$$r; done

reinit: wipe init

# Primarily for Yarik's initial playground
wipe:
	for r in $(REPOS); do rm -rf `echo $${r#*/} | sed -e 's,.git,,g'`; done
	rm -rf .git*

.PHONY: init reinit wipe install status build test clean dist-clean
