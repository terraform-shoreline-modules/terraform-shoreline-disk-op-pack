CLUSTER?=alpha
SHORE_URL?=https://test.us.api.shoreline-${CLUSTER}.io
SHORE_TOKEN?=`grep -B1 ${CLUSTER} ~/.ops_auth.yaml | grep "Token:" | tail -n 1 | cut -d':' -f2 | tr -d ' '`

TEST_SCRIPT=./run-test.sh

test:
	SHORELINE_URL=$(SHORE_URL) SHORELINE_TOKEN=$(SHORE_TOKEN) CLUSTER=$(CLUSTER)  $(TEST_SCRIPT)

init:
	SHORELINE_URL=$(SHORE_URL) SHORELINE_TOKEN=$(SHORE_TOKEN) terraform init

install:
	SHORELINE_URL=$(SHORE_URL) SHORELINE_TOKEN=$(SHORE_TOKEN) terraform apply --auto-approve

remove:
	SHORELINE_URL=$(SHORE_URL) SHORELINE_TOKEN=$(SHORE_TOKEN) terraform destroy --auto-approve

setup:
	SHORELINE_URL=$(SHORE_URL) SHORELINE_TOKEN=$(SHORE_TOKEN) CLUSTER=$(CLUSTER) $(TEST_SCRIPT) setup

cleanup:
	SHORELINE_URL=$(SHORE_URL) SHORELINE_TOKEN=$(SHORE_TOKEN) CLUSTER=$(CLUSTER) $(TEST_SCRIPT) cleanup

test-only:
	SHORELINE_URL=$(SHORE_URL) SHORELINE_TOKEN=$(SHORE_TOKEN) CLUSTER=$(CLUSTER) $(TEST_SCRIPT) test-only

debug-test:
	SHORELINE_URL=$(SHORE_URL) SHORELINE_TOKEN=$(SHORE_TOKEN) CLUSTER=$(CLUSTER) $(TEST_SCRIPT) test-only


distclean:
	rm -rf terraform.tfstate terraform.tfstate.backup

.PHONY: distclean
