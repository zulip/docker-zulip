class zulip::supervisor {
  $supervisor_packages = [# Needed to run supervisor
                          "supervisor",
                          ]
  package { $supervisor_packages: ensure => "installed" }

  file { "/etc/supervisor/supervisord.conf":
    require => Package[supervisor],
    ensure => file,
    owner => "root",
    group => "root",
    mode => 644,
    source => "puppet:///modules/zulip/supervisor/supervisord.conf",
  }

  if $zulip::base::release_name == "xenial" {
    exec {"enable supervisor":
      unless => "systemctl is-enabled supervisor",
      command => "systemctl enable supervisor",
      require => Package["supervisor"],
    }
  }
}
