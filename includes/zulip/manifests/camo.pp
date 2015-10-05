class zulip::camo {
  include zulip::supervisor
  $camo_packages = [# Needed for camo
                    "nodejs",
                    "camo",
                    ]
  package { $camo_packages: ensure => "installed" }
  # The configuration file is generated at install time
  file { "/etc/supervisor/conf.d/camo.conf":
    require => Package[camo],
    ensure => file,
    owner => "root",
    group => "root",
    mode => 644,
    source => "puppet:///modules/zulip/supervisor/conf.d/camo.conf",
  }
}
