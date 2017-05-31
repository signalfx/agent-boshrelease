# SignalFx Agent BOSH Release

This is a BOSH release of the SignalFx collectd agent. It uses a [self-contained
bundle of collectd](https://github.com/signalfx/collectd-build-bundle) to run.

## Configuration

Specify your SignalFx access token with the `access_token` property in your
manifest entry for this release.

There are two ways to configure the collectd agent: 1) putting config files in
the `src/signalfx-collectd/managed_config` directory; or 2) by specifying the
config file as a heredoc for the `collectd_config` property in your deployment
manifest.  The first method is useful if you want to create a custom re-usable
release and the second is good for quick config of the default agent.

### Method 1: src/signalfx-collectd/managed_config Dir
To add collectd configuration files, simply add them to the dir
`src/signalfx-collectd/managed_config` and generate a new release.  This
release will include these files.  This method is not very flexible since
the config files are all static and a new release must be generated for each
combination of services monitored.  It is most useful for making a new base
release.

### Method 2: Deployment YAML Property
You can also add a property to the `signalfx-agent` job in your
deployment manifest called `collectd_configs`.  This should be the contents of
all of the custom collectd config files concatenated together as a heredoc.
These will be added to the `managed_config` dir that collectd reads config
from.

Example:

```
...
instance_groups:
- name: agent-with-redis
  jobs:
  - name: signalfx-agent
    release: signalfx-agent
    properties:
      access_token: abc123
      collectd_configs: |
        <LoadPlugin python>
          Globals true
        </LoadPlugin>

        <Plugin python>
          ModulePath "/usr/share/collectd/redis"
          Import "redis_info"

          <Module redis_info>
            Host "localhost"
            Port 6379
            Auth "password"
            Redis_uptime_in_seconds "gauge"
          </Module>
        </Plugin>
...
```

This is more flexible although it still requires you to hardcode certain config
options like passwords.  [BOSH variables](https://bosh.io/docs/cli-int.html)
are one way to deal with this more effectively.

### Collectd Plugins
This release includes most of our Python plugins installed to the BOSH package
dir `/var/vcap/packages/signalfx-collectd/plugins/<integration name>`, so make
sure to use this directory when specifying `ModulePath` when configuring Python
plugins.  The `Import` statement will be the same as example config files, as
well as the `<Module>` tags.  For example, the Elasticsearch plugin is
installed at `/var/vcap/packages/signalfx-collectd/plugins/elasticsearch`, so
its config file would look like:

```
<LoadPlugin "python">
    Globals true
</LoadPlugin>

<Plugin "python">
    ModulePath "/var/vcap/packages/signalfx-collectd/plugins/elasticsearch"

    Import "elasticsearch_collectd"

    <Module "elasticsearch_collectd">
	   ....
    </Module>
</Plugin>
```

## TODO

 - Automatically discover services to monitor via [BOSH
     links](https://bosh.io/docs/links.html).  BOSH links are available as an
     array in the ERB job templates as `@links`.

## Dev Setup

To modify the release:

 - Install the [BOSH CLI tool 2+](http://bosh.io/docs/cli-v2.html)
 - Install [BOSH-Lite](https://github.com/cloudfoundry/bosh-lite) -- you don't
     need to deploy Cloud Foundry to it
 - Run `bosh alias-env bosh-lite -e 192.168.50.4 --ca-cert=<BOSH_LITE_DIR>/ca/certs/ca.crt`
     -- changing `<BOSH_LITE_DIR>` to the dir that you cloned the bosh-lite
     repo to.
 - Download `cloud.yml` in [this gist](https://gist.github.com/keitwb/b0503487f29fb4c19ba5281ea5969185#file-cloud-yml)
     and save it to `/tmp/cloud.yml`.
 - Run `bosh -e bosh-lite ucc /tmp/cloud.yml` to set your cloud config for
     BOSH.
 - Make changes to this repo.
 - Run `make bosh-dev-release` to test on bosh-lite.
