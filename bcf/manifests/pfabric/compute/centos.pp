class bcf::pfabric::compute::centos inherits bcf::pfabric::compute {
    # load 8021q module on boot
    file {'/etc/sysconfig/modules/8021q.modules':
        ensure  => file,
        mode    => 0777,
        content => "modprobe 8021q",
    }
    exec { "load 8021q":
        command => "modprobe 8021q",
        path    => $binpath,
    }

    # lldp
    file { "/bin/send_lldp":
        ensure  => file,
        mode    => 0777,
    }
    file { "/usr/lib/systemd/system/send_lldp.service":
        ensure  => file,
        content => "
[Unit]
Description=send lldp
After=syslog.target network.target
[Service]
Type=simple
ExecStart=/bin/send_lldp --system-desc 5c:16:c7:00:00:00 --system-name $fqdn -i 10 --network_interface $uplink1,$uplink2
Restart=always
StartLimitInterval=60s
StartLimitBurst=3
[Install]
WantedBy=multi-user.target
",
    }->
    file { '/etc/systemd/system/multi-user.target.wants/send_lldp.service':
        ensure => link,
        target => '/usr/lib/systemd/system/send_lldp.service',
        notify => Service['send_lldp'],
    }
    service { "send_lldp":
        ensure  => running,
        enable  => true,
        require => [File['/bin/send_lldp'], File['/etc/systemd/system/multi-user.target.wants/send_lldp.service']],
    }

    # bond configuration
    file { "/etc/sysconfig/network-scripts/ifcfg-bond0":
        ensure  => file,
        content => "
DEVICE=%(bond)s
USERCTL=no
BOOTPROTO=none
ONBOOT=yes
NM_CONTROLLED=no
BONDING_OPTS='mode=2 miimon=50 updelay=15000'
",
    }
    file { "/etc/sysconfig/network-scripts/ifcfg-${uplink1}":
        ensure  => file,
        content => "
DEVICE=${uplink1}
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
USERCTL=no
MASTER=bond0
SLAVE=yes
",
    }
    file { "/etc/sysconfig/network-scripts/ifcfg-${uplink2}":
        ensure  => file,
        content => "
DEVICE=${uplink2}
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
USERCTL=no
MASTER=bond0
SLAVE=yes
",
    }

    # config /etc/neutron/neutron.conf
    ini_setting { "neutron.conf debug":
        ensure            => present,
        path              => '/etc/neutron/neutron.conf',
        section           => 'DEFAULT',
        key_val_separator => '=',
        setting           => 'debug',
        value             => 'True',
        notify            => Service['neutron-server'],
    }
    ini_setting { "neutron.conf report_interval":
        ensure            => present,
        path              => '/etc/neutron/neutron.conf',
        section           => 'agent',
        key_val_separator => '=',
        setting           => 'report_interval',
        value             => '60',
        notify            => Service['neutron-server'],
    }
    ini_setting { "neutron.conf agent_down_time":
        ensure            => present,
        path              => '/etc/neutron/neutron.conf',
        section           => 'DEFAULT',
        key_val_separator => '=',
        setting           => 'agent_down_time',
        value             => '150',
        notify            => Service['neutron-server'],
    }
    ini_setting { "neutron.conf service_plugins":
        ensure            => present,
        path              => '/etc/neutron/neutron.conf',
        section           => 'DEFAULT',
        key_val_separator => '=',
        setting           => 'service_plugins',
        value             => 'router',
        notify            => Service['neutron-server'],
    }
    ini_setting { "neutron.conf dhcp_agents_per_network":
        ensure            => present,
        path              => '/etc/neutron/neutron.conf',
        section           => 'DEFAULT',
        key_val_separator => '=',
        setting           => 'dhcp_agents_per_network',
        value             => '1',
        notify            => Service['neutron-server'],
    }
    ini_setting { "neutron.conf network_scheduler_driver":
        ensure            => present,
        path              => '/etc/neutron/neutron.conf',
        section           => 'DEFAULT',
        key_val_separator => '=',
        setting           => 'network_scheduler_driver',
        value             => 'neutron.scheduler.dhcp_agent_scheduler.WeightScheduler',
        notify            => Service['neutron-server'],
    }
    ini_setting { "neutron.conf notification driver":
        ensure            => present,
        path              => '/etc/neutron/neutron.conf',
        section           => 'DEFAULT',
        key_val_separator => '=',
        setting           => 'notification_driver',
        value             => 'messaging',
        notify            => Service['neutron-server'],
    }

    # config /etc/neutron/plugins/ml2/ml2_conf.ini
    ini_setting { "ml2 type dirvers":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'ml2',
        key_val_separator => '=',
        setting           => 'type_drivers',
        value             => 'vlan',
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 tenant network types":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'ml2',
        key_val_separator => '=',
        setting           => 'tenant_network_types',
        value             => 'vlan',
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 tenant network vlan ranges":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'ml2_type_vlan',
        key_val_separator => '=',
        setting           => 'network_vlan_ranges',
        value             => "$network_vlan_ranges",
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 mechanism drivers":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'ml2',
        key_val_separator => '=',
        setting           => 'mechanism_drivers',
        value             => 'openvswitch, bsn_ml2',
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 restproxy ssl cert directory":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'restproxy',
        key_val_separator => '=',
        setting           => 'ssl_cert_directory',
        value             => '/var/lib/neutron',
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 restproxy servers":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'restproxy',
        key_val_separator => '=',
        setting           => 'servers',
        value             => "$bcf_controllers",
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 restproxy server auth":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'restproxy',
        key_val_separator => '=',
        setting           => 'server_auth',
        value             => '$bcf_username:$bcf_password',
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 restproxy server ssl":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'restproxy',
        key_val_separator => '=',
        setting           => 'server_ssl',
        value             => 'True',
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 restproxy auto sync on failure":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'restproxy',
        key_val_separator => '=',
        setting           => 'auto_sync_on_failure',
        value             => 'True',
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 restproxy consistency interval":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'restproxy',
        key_val_separator => '=',
        setting           => 'consistency_interval',
        value             => 60,
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 restproxy neutron_id":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'restproxy',
        key_val_separator => '=',
        setting           => 'neutron_id',
        value             => "$neutron_id",
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 restproxy keystone_auth_url":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'restproxy',
        key_val_separator => '=',
        setting           => 'auth_url',
        value             => "$keystone_auth_url",
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 restproxy keystone_auth_user":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'restproxy',
        key_val_separator => '=',
        setting           => 'auth_user',
        value             => "$keystone_auth_user",
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 restproxy keystone_password":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'restproxy',
        key_val_separator => '=',
        setting           => 'auth_password',
        value             => "$keystone_password",
        notify            => Service['neutron-server'],
    }
    ini_setting { "ml2 restproxy keystone_auth_tenant":
        ensure            => present,
        path              => '/etc/neutron/plugins/ml2/ml2_conf.ini',
        section           => 'restproxy',
        key_val_separator => '=',
        setting           => 'auth_tenant',
        value             => "$keystone_auth_tenant",
        notify            => Service['neutron-server'],
    }

    # make services in right state
    service { 'neutron-server':
        ensure  => running,
        enable  => true,
        path    => $binpath,
        require => Exec['purge bcf key'],
    }

    ini_setting { "integration bridge":
        ensure            => present,
        path              => '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini',
        section           => 'ovs',
        key_val_separator => '=',
        setting           => 'integration_bridge',
        value             => "$br_int",
        notify            => Service['neutron-openvswitch-agent'],
    }
    ini_setting { "bridge mappings":
        ensure            => present,
        path              => '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini',
        section           => 'ovs',
        key_val_separator => '=',
        setting           => 'bridge_mappings',
        value             => "$br_mappings",
        notify            => Service['neutron-openvswitch-agent'],
    }
    service { 'neutron-openvswitch-agent':
        ensure            => running,
        enable            => true,
        path              => $binpath,
    }

    #TODO: dhcp l3 agenty
}
