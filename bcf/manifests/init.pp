class bcf (
    $mode                = hiera('bcf::mode'),
    $role                = hiera('bcf::role'),
    $os                  = hiera('bcf::os'),
    $uplink1             = hiera('bcf::uplink1'),
    $uplink2             = hiera('bcf::uplink2'),
    $bcf_username        = hiera('bcf::bcf_username'),
    $bcf_password        = hiera('bcf::bcf_password'),
    $neutron_id          = hiera('bcf::neutron_id'),
    $bcf_controllers     = hiera('bcf::bcf_controllers'),
    $network_vlan_ranges = hiera('bcf::network_vlan_ranges'),
    $keystone_auth_url   = hiera('bcf::keystone_auth_url'),
    $keystone_auth_user  = hiera('bcf::keystone_auth_user'),
    $keystone_password   = hiera('bcf::keystone_password'),
    $keystone_auth_tenant= hiera('bcf::keystone_auth_tenant'),
    $br_int              = hiera('bcf::br_int'),
    $br_mappings         = hiera('bcf::br_mappings'),
    $binpath             = "/usr/local/bin/:/bin/:/usr/bin:/usr/sbin:/usr/local/sbin:/sbin"
) {
    case $mode {
        'pfabric': {include bcf::pfabric}
    }
}
