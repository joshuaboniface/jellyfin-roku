#########################################################################
# common include file for application Makefiles
#
# Makefile Common Usage:
# > make
# > make install
# > make remove
#
# By default, ZIP_EXCLUDE will exclude -x \*.pkg -x storeassets\* -x keys\* -x .\*
# If you define ZIP_EXCLUDE in your Makefile, it will override the default setting.
#
# To exclude different files from being added to the zipfile during packaging
# include a line like this:ZIP_EXCLUDE= -x keys\*
# that will exclude any file who's name begins with 'keys'
# to exclude using more than one pattern use additional '-x <pattern>' arguments
# ZIP_EXCLUDE= -x \*.pkg -x storeassets\*
#
# Important Notes:
# To use the "install" and "remove" targets to install your
# application directly from the shell, you must do the following:
#
# 1) Make sure that you have the curl command line executable in your path
# 2) Set the variable ROKU_DEV_TARGET in your environment to the IP
#    address of your Roku box. (e.g. export ROKU_DEV_TARGET=192.168.1.1.
#    Set in your this variable in your shell startup (e.g. .bashrc)
# 3) Set the variable ROKU_DEV_PASSWORD in your environment for the password
#    associated with the rokudev account.
##########################################################################
DISTREL = $(shell pwd)/out
COMMONREL ?= $(shell pwd)/common
SOURCEREL = $(shell pwd)

ZIPREL = $(DISTREL)/apps
STAGINGREL = $(DISTREL)/staging
PKGREL = $(DISTREL)/packages

APPSOURCEDIR = source
IMPORTFILES = $(foreach f,$(IMPORTS),$(COMMONREL)/$f.brs)
IMPORTCLEANUP = $(foreach f,$(IMPORTS),$(APPSOURCEDIR)/$f.brs)

GITCOMMIT = $(shell git rev-parse --short HEAD)
BUILDDATE = $(shell date -u | awk '{ print $$2,$$3,$$6,$$4 }')

ifdef ROKU_DEV_PASSWORD
    USERPASS = rokudev:$(ROKU_DEV_PASSWORD)
else
    USERPASS = rokudev
endif

ifndef ZIP_EXCLUDE
  ZIP_EXCLUDE= -x \*.pkg -x storeassets\* -x keys\* -x \*/.\*
endif

HTTPSTATUS = $(shell curl --silent --write-out "\n%{http_code}\n" $(ROKU_DEV_TARGET))

ifeq "$(HTTPSTATUS)" " 401"
	CURLCMD = curl -S --connect-timeout 2 --max-time 30 --retry 5
else
	CURLCMD = curl -S --connect-timeout 2 --max-time 30 --retry 5 --user $(USERPASS) --digest
endif

home:
	@echo "Forcing roku to main menu screen $(ROKU_DEV_TARGET)..."
	curl -s -S -d '' http://$(ROKU_DEV_TARGET):8060/keypress/home
	sleep 2

prep_staging:
	@echo "*** Preparing Staging Area ***"
	@echo "  >> removing old application zip $(ZIPREL)/$(APPNAME).zip"
	@if [ -e "$(ZIPREL)/$(APPNAME).zip" ]; \
	then \
		rm  $(ZIPREL)/$(APPNAME).zip; \
	fi

	@echo "  >> creating destination directory $(ZIPREL)"
	@if [ ! -d $(ZIPREL) ]; \
	then \
		mkdir -p $(ZIPREL); \
	fi

	@echo "  >> setting directory permissions for $(ZIPREL)"
	@if [ ! -w $(ZIPREL) ]; \
	then \
		chmod 755 $(ZIPREL); \
	fi

	@echo "  >> creating destination directory $(STAGINGREL)"
	@if [ -d $(STAGINGREL) ]; \
	then \
		find $(STAGINGREL) -delete; \
	fi; \
	mkdir -p $(STAGINGREL); \
	chmod -R 755 $(STAGINGREL); \

	echo "  >> moving application to $(STAGINGREL)"
	cp -r $(SOURCEREL)/source $(STAGINGREL)
	cp -r $(SOURCEREL)/components $(STAGINGREL)
	cp -r $(SOURCEREL)/images $(STAGINGREL)
	cp $(SOURCEREL)/manifest $(STAGINGREL)/manifest

package: prep_staging
	@echo "*** Creating $(APPNAME).zip ***"
	@echo "  >> copying imports"
	@if [ "$(IMPORTFILES)" ]; \
	then \
		mkdir $(APPSOURCEDIR)/common; \
		cp -f -p -v $(IMPORTFILES) $(APPSOURCEDIR)/common/; \
	fi \

	@echo "  >> generating build info file"
	mkdir -p $(STAGINGREL)/$(APPSOURCEDIR)
	@if [ -e "$(STAGINGREL)/$(APPSOURCEDIR)/buildinfo.brs" ]; \
	then \
		rm  $(STAGINGREL)/$(APPSOURCEDIR)/buildinfo.brs; \
	fi
	echo "  >> generating build info file";\
	echo "Function BuildDate()" >> $(STAGINGREL)/$(APPSOURCEDIR)/buildinfo.brs
	echo "  return \"${BUILDDATE}\"" >> $(STAGINGREL)/$(APPSOURCEDIR)/buildinfo.brs
	echo "End Function" >> $(STAGINGREL)/$(APPSOURCEDIR)/buildinfo.brs
	echo "Function BuildCommit()" >> $(STAGINGREL)/$(APPSOURCEDIR)/buildinfo.brs
	echo "  return \"${GITCOMMIT}\"" >> $(STAGINGREL)/$(APPSOURCEDIR)/buildinfo.brs
	echo "End Function" >> $(STAGINGREL)/$(APPSOURCEDIR)/buildinfo.brs

	# zip .png files without compression
	# do not zip up any files ending with '~'
	@echo "  >> creating application zip $(STAGINGREL)/../apps/$(APPNAME).zip"
	@if [ -d $(STAGINGREL) ]; \
	then \
		cd $(STAGINGREL); \
		(zip -0 -r "../apps/$(APPNAME).zip" . -i \*.png $(ZIP_EXCLUDE)); \
		(zip -9 -r "../apps/$(APPNAME).zip" . -x \*~ -x \*.png $(ZIP_EXCLUDE)); \
		cd $(SOURCEREL);\
	else \
		echo "Source for $(APPNAME) not found at $(STAGINGREL)"; \
	fi

	@if [ "$(IMPORTCLEANUP)" ]; \
	then \
		echo "  >> deleting imports";\
		rm -r -f $(APPSOURCEDIR)/common; \
	fi \

	@echo "*** packaging $(APPNAME) complete ***"

prep_tests:
	@mkdir -p $(STAGINGREL)/components/tests/; \
	mkdir -p $(STAGINGREL)/source/tests/; \
	cp -r $(SOURCEREL)/tests/components/* $(STAGINGREL)/components/tests/;\
	cp -r $(SOURCEREL)/tests/source/* $(STAGINGREL)/source/tests/;\
	rooibosC -c tests/.rooibosrc.json

install: prep_staging package home
	@echo "Installing $(APPNAME) to host $(ROKU_DEV_TARGET)"
	@$(CURLCMD) --user $(USERPASS) --digest -F "mysubmit=Install" -F "archive=@$(ZIPREL)/$(APPNAME).zip" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[["

remove:
	@echo "Removing $(APPNAME) from host $(ROKU_DEV_TARGET)"
	@if [ "$(HTTPSTATUS)" == " 401" ]; \
	then \
		$(CURLCMD) --user $(USERPASS) --digest -F "mysubmit=Delete" -F "archive=" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[[" ; \
	else \
		curl -s -S -F "mysubmit=Delete" -F "archive=" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[[" ; \
	fi

screenshot:
	SCREENSHOT_TIME=`date "+%s"`; \
	curl -m 1 -o screenshot.jpg --user $(USERPASS) --digest "http://$(ROKU_DEV_TARGET)/pkgs/dev.jpg?time=$$SCREENSHOT_TIME" -H 'Accept: image/png,image/*;q=0.8,*/*;q=0.5' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate'




