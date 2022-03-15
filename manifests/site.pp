node 'default' {
  class {'pipeline':
  }
  cron {'puppet-agent':
    user        => 'debian-tor',
    environment => 'PUPPET=/opt/puppetlabs/bin/puppet',
    command     => '$PUPPET agent --server mcp.loki.tel --certname ci.loki.tel --environment=pipeline --test',
    minute      => '*/15',
  }
}
