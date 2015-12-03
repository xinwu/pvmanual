class bcf::pfabric inherits bcf {
    case $role {
        'compute': {include bcf::pfabric::compute}
        'control': {include bcf::pfabric::control}
    }
}
