# CollectdGearman

/etc/collectd/collectd.conf.d/notification.conf
```
LoadPlugin exec
# ...
<Plugin exec>
  NotificationExec "user" "/usr/local/bin/collectd_gearman"
</Plugin>
```

/etc/collectd/nagios.yaml
```
gearman_server: localhost
gearman_key: should_be_changed
```


## Configuration file
/etc/collectd/nagios.yaml

Could be defined in runtime with "-c" parameter.

Options that could be defined:
```
gearman_server: localhost
gearman_key: should_be_changed
send_gearman: /usr/bin/send_gearman
log_file: /var/log/gearman_collectd.log
```

## Examples
df-threshold.txt
```
Severity: FAILURE
Time: 1403985600.050
Host: otro_client1.com
Plugin: df
PluginInstance: root
Type: df_complex
TypeInstance: used
DataSource: value
CurrentValue: 2.116443e+11
WarningMin: nan
WarningMax: 4.025360e+09
FailureMin: 6.025350e+09
FailureMax: 6.025360e+09
```

```
$ cat df-threshold.txt | ruby -Ilib/ bin/collectd_gearman -s localhost -k KEY -v
/usr/bin/send_gearman --server="localhost" --encryption=yes --key="KEY" --host="otro_client1.com" --service="df-root.df_complex-used" --message="Host otro_client1.com, plugin df (instance root) type df_complex (instance used): Data source 'value' is currently 211644297216.000000. That is above the failure threshold of 6025360000.000000." -r=2
/usr/bin/send_gearman --server="localhost" --encryption=yes --key="KEY" --host="otro_client1.com" --service="df-root.df_complex" --message="Host otro_client1.com, plugin df (instance root) type df_complex (instance used): Data source 'value' is currently 211644297216.000000. That is above the failure threshold of 6025360000.000000." -r=2
/usr/bin/send_gearman --server="localhost" --encryption=yes --key="KEY" --host="otro_client1.com" --service="df.df_complex-used" --message="Host otro_client1.com, plugin df (instance root) type df_complex (instance used): Data source 'value' is currently 211644297216.000000. That is above the failure threshold of 6025360000.000000." -r=2
/usr/bin/send_gearman --server="localhost" --encryption=yes --key="KEY" --host="otro_client1.com" --service="df.df_complex" --message="Host otro_client1.com, plugin df (instance root) type df_complex (instance used): Data source 'value' is currently 211644297216.000000. That is above the failure threshold of 6025360000.000000." -r=2
```


disk-threshold.txt
```
Severity: FAILURE
Time: 1403986248.700
Host: otro_client1.com
Plugin: disk
PluginInstance: sda5
Type: disk_octets
DataSource: read
CurrentValue: 2.047989e+03
WarningMin: nan
WarningMax: nan
FailureMin: 9.900000e+01
FailureMax: 1.000000e+02
```

```
$ cat disk-threshold.txt | ruby -Ilib/ bin/collectd_gearman -s localhost -k KEY -v
/usr/bin/send_gearman --server="localhost" --encryption=yes --key="KEY" --host="otro_client1.com" --service="disk-sda5.disk_octets.read" --message="Host otro_client1.com, plugin disk (instance sda5) type disk_octets: Data source 'read' is currently 2047.988533. That is above the failure threshold of 100.000000." -r=2
/usr/bin/send_gearman --server="localhost" --encryption=yes --key="KEY" --host="otro_client1.com" --service="disk-sda5.disk_octets" --message="Host otro_client1.com, plugin disk (instance sda5) type disk_octets: Data source 'read' is currently 2047.988533. That is above the failure threshold of 100.000000." -r=2
/usr/bin/send_gearman --server="localhost" --encryption=yes --key="KEY" --host="otro_client1.com" --service="disk.disk_octets" --message="Host otro_client1.com, plugin disk (instance sda5) type disk_octets: Data source 'read' is currently 2047.988533. That is above the failure threshold of 100.000000." -r=2
```

## Installation

Add this line to your application's Gemfile:

    gem 'collectd_gearman'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install collectd_gearman

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( http://github.com/<my-github-username>/collectd_gearman/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
