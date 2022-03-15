# Tor relay configs for loki.tel
class pipeline {
    package {'tor':
    ensure => 'installed',
  }
  service {'tor':
    ensure     => 'running',
    start      => '/usr/bin/sudo /usr/bin/systemctl start tor.service',
    stop       => '/usr/bin/sudo /usr/bin/systemctl stop tor.service',
    status     => '/usr/bin/sudo /usr/bin/systemctl status tor.service',
    restart    => '/usr/bin/sudo /usr/bin/systemctl restart tor.service',
    hasstatus  => 'false',
    hasrestart => 'true',
    require    => Package['tor'],
    subscribe  => [
      File['/etc/tor/torrc'],
      File['/etc/tor/info.html'],
    ]
  }
  file {'/etc/tor/torrc':
    ensure => 'file',
    source => 'puppet:///modules/pipeline/torrc',
  }
  file {'/etc/tor/info.html':
    ensure => 'file',
    source => 'puppet:///modules/pipeline/info.html',
  }
  file {'/etc/tor/tor-exit-notice.html':
    ensure => 'absent',
  }
}

