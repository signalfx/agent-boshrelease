# SignalFx Agent BOSH Release

This is a BOSH release of the SignalFx collectd agent. The agent runs on the
BOSH-managed VM using the [runc](https://github.com/opencontainers/runc) tool
for running simple Linux containers.  Runc is what Docker uses underneath the
covers.  This is a much simpler approach than running the agent in a full-blown
Docker installation, or having to install collectd directly on the various
stemcells.  This container only makes use of the *mount* namespace so there is
no complexity around routing network requests from collectd.

This should run on any stemcell that has a reasonably new Linux kernel (3.10+,
although supposedly 2.6.2x will work with the right patches for namespace
support).  Cgroups do have to be mounted at `/sys/fs/cgroups` but the startup
script takes care of mounting that if it is not already.

## Configuration
To add collectd configuration files, simply add them to the dir
`src/signalfx-collectd/managed_config` and they will be copied into the
container and used by the agent.

### Collectd Plugins
All python plugin modules are installed to
`/usr/share/collectd/<integration_name>`, so make sure your configuration
reflects that in the `ModulePath` property.  For example, the Elasticsearch
plugin is installed at `/usr/share/collectd/elasticsearch`, so its config file
would look like:

```
<LoadPlugin "python">
    Globals true
</LoadPlugin>

<Plugin "python">
    ModulePath "/usr/share/collectd/elasticsearch"

    Import "elasticsearch_collectd"

    <Module "elasticsearch_collectd">
	   ....
    </Module>
</Plugin>
```

## Dev Setup

 - Install the [BOSH CLI tool 2+](http://bosh.io/docs/cli-v2.html)
 - Install [BOSH-Lite](https://github.com/cloudfoundry/bosh-lite) -- you don't
     need to deploy Cloud Foundry to it
 - Run `bosh alias-env bosh-lite -e 192.168.50.4 --ca-cert=<BOSH_LITE_DIR>/ca/certs/ca.crt`
     -- changing `<BOSH_LITE_DIR>` to the dir that you cloned the bosh-lite
     repo to.
 - Download `cloud.yml` in [this gist](https://gist.github.com/keitwb/b0503487f29fb4c19ba5281ea5969185#file-cloud-yml)
     and save it to `/tmp/cloud.yml`.
 - Run `bosh -e bosh-lite ucc /tmp/cloud.yml` -- fixing the path to where
     you downloaded it
