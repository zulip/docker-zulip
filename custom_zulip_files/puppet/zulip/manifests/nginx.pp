class zulip::nginx {
  $web_packages = [# Needed to run nginx with the modules we use
                   "nginx-full",
                   ]
  package { $web_packages: ensure => "installed" }

  file { "/etc/nginx/zulip-include/":
    require => Package["nginx-full"],
    recurse => true,
    owner  => "root",
    group  => "root",
    mode => 644,
    source => "puppet:///modules/zulip/nginx/zulip-include-common/",
  }

  file { "/etc/nginx/nginx.conf":
    require => Package["nginx-full"],
    ensure => file,
    owner  => "root",
    group  => "root",
    mode => 644,
    source => "puppet:///modules/zulip/nginx/nginx.conf",
  }

  file { "/etc/nginx/uwsgi_params":
    require => Package["nginx-full"],
    ensure => file,
    owner  => "root",
    group  => "root",
    mode => 644,
    source => "puppet:///modules/zulip/nginx/uwsgi_params",
  }

  file { "/etc/nginx/sites-enabled/default":
    ensure => absent,
  }

  file { '/var/log/nginx':
    ensure     => "directory",
    owner      => "zulip",
    group      => "adm",
    mode       => 650
  }

  # Depending on the environment, ignoreNginxService is set, meaning we
  # don't want/need supervisor to be started/stopped
  # /bin/true is used as a decoy command, to maintain compatibility with other
  # code using the supervisor service.
  if $ignoreNginxService != undef and $ignoreNginxService {
    service { "nginx":
      ensure     => running,
      require    => [
        File["/var/log/nginx"],
        Package["nginx-full"],
      ],
      hasstatus  => true,
      status     => "/bin/true",
      hasrestart => true,
      restart => "/bin/true"
    }
  } else {
    service { "supervisor":
      ensure => running,
      require    => [
        File["/var/log/nginx"],
        Package["nginx-full"],
      ],
    }
  }
}
