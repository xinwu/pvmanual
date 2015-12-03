class bcf::pfabric::control inherits bcf::pfabric {
    case $os {
        'centos': {include bcf::pfabric::control::centos}
    }
}
