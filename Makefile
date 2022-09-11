SHELL := bash

default:

test:
	git config -l -f index.ini >/dev/null && echo PASS || echo FAIL

update:
	./bin/update-bpan-index --push $(NAME)
