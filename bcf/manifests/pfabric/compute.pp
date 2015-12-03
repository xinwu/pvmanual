class bcf::pfabric::compute inherits bcf::pfabric {
    case $os {
        'centos': {include bcf::pfabric::compute::centos}
    }
}
