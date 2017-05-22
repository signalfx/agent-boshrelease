collectd-rootfs-blob:
	rm -rf tmp/collectd-rootfs.tar.gz
	bash make-collectd-rootfs
	bosh add-blob tmp/collectd-rootfs.tar.gz signalfx-collectd/collectd-rootfs.tar.gz

runc-blob:
	rm -rf tmp/runc-linux-amd64
	bash make-runc-blob
	bosh add-blob tmp/runc-linux-amd64 runc/runc-linux-amd64

blobs: runc-blob collectd-rootfs-blob

manifest/agent-with-redis.yml: .sfx-token manifest/agent-with-redis.yml.template
	bosh int manifest/agent-with-redis.yml.template \
		-v signalfx_api_token=$$(cat .sfx-token) \
		-v redis_password=password \
		> manifest/agent-with-redis.yml

bosh-dev-deploy: manifest/agent-with-redis.yml
	bosh create-release --force
	bosh -e bosh-lite upload-release --fix
	bosh -e bosh-lite -d agent-with-redis deploy manifest/agent-with-redis.yml

.PHONY: collectd-rootfs-blob runc-blob blobs bosh-dev-release
