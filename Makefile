
#########################################################################
# Makefile Usage:
# > make test ' run all tests
# > make testFailures ' run all tests and show only failures
#
# 1) Make sure that you have the curl command line executable in your path
# 2) Set the variable ROKU_DEV_TARGET in your environment to the IP
#    address of your Roku box. (e.g. export ROKU_DEV_TARGET=192.168.1.1.
#    Set in your this variable in your shell startup (e.g. .bashrc)
# 3) and set up the ROKU_DEV_PASSWORD environment variable, too
##########################################################################

APPNAME = Jellyfin_Roku
VERSION = 0.0.1
ROKU_TEST_ID = 1
ROKU_TEST_WAIT_DURATION = 5

ZIP_EXCLUDE= -x rooibos/**\* -x xml/* -x artwork/* -x \*.pkg -x storeassets\* -x keys\* -x \*/.\* -x *.git* -x *.DS* -x *.pkg* -x dist/**\*  -x out/**\* 

include app.mk

test: prep_staging prep_tests remove install
	echo "Running tests"

deploy: prep_staging remove install
