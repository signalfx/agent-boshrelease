BUILD_IMAGE := quay.io/signalfuse/agent-boshrelease-build:latest
DOCKER_RUN := docker run --rm -v $$(pwd):/opt/bosh-release $(BUILD_IMAGE)

# The sed transforms "1.2.3-1.0" to "1.2.3-1"
BUNDLE_VERSION := $(shell cat VERSION | sed 's/\(-.\)\..*$$/\1/')

collectd-bundle-$(BUNDLE_VERSION).tar.gz:
	wget https://github.com/signalfx/collectd-build-bundle/releases/download/v$(BUNDLE_VERSION)/collectd-bundle-$(BUNDLE_VERSION).tar.gz

collectd-blob: collectd-bundle-$(BUNDLE_VERSION).tar.gz
	grep $(BUNDLE_VERSION) packages/signalfx-collectd/spec || (echo 'YOU NEED TO UPDATE THE COLLECTD BUNDLE VERSION IN THE packages/signalfx-collectd/spec FILE!' && exit 1)
	bosh add-blob $< signalfx-collectd/$<

build-image: Dockerfile
	docker pull quay.io/signalfuse/agent-boshrelease-build || true
	docker build -t quay.io/signalfuse/agent-boshrelease-build .

final-release: collectd-blob build-image
	rm -rf .dev_builds
	@$(MAKE) collectd-blob
	mkdir -p tmp
	rm -f tmp/release.tar.gz
	$(DOCKER_RUN) bosh create-release --final --name signalfx-agent --force --tarball tmp/release.tar.gz --version $$(cat VERSION)

manifest/agent-with-redis.yml: .sfx-token manifest/agent-with-redis.yml.template
	bosh int manifest/agent-with-redis.yml.template \
		-v signalfx_access_token=$$(cat .sfx-token) \
		-v redis_password=password \
		> manifest/agent-with-redis.yml

bosh-dev-deploy: manifest/agent-with-redis.yml
	bosh create-release --force
	bosh -e bosh-lite upload-release --fix
	bosh -e bosh-lite -d agent-with-redis deploy manifest/agent-with-redis.yml

.PHONY: final-release bosh-dev-release
