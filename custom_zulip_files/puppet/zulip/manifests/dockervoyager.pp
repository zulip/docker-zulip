# This class includes all the modules you need to install/run an Zulip installation
# in a single container (without the database, memcached, redis services)
# The database, memcached, redis services need to be run in seperate containers.
# Through this split of services, it is easier to scale the services to the needs.
class zulip::dockervoyager {
  include zulip::base
  # zulip::apt_repository must come after zulip::base
  include zulip::apt_repository
  include zulip::app_frontend
  $appdb_packages = [# Needed to run process_fts_updates
                     "python-psycopg2",
                     ]
  define safepackage ( $ensure = present ) {
    if !defined(Package[$title]) {
      package { $title: ensure => $ensure }
    }
  }
  safepackage { $appdb_packages: ensure => "installed" }

  $ignoreSupervisorService = true

  include zulip::supervisor

  file { "/etc/supervisor/conf.d/cron.conf":
    require => Package[supervisor],
    ensure => file,
    owner => "root",
    group => "root",
    mode => 644,
    source => "puppet:///modules/zulip/supervisor/conf.d/cron.conf",
  }
  file { "/etc/supervisor/conf.d/nginx.conf":
    require => Package[supervisor],
    ensure => file,
    owner => "root",
    group => "root",
    mode => 644,
    source => "puppet:///modules/zulip/supervisor/conf.d/nginx.conf",
  }

  # process_fts_updates installation
  file { "/usr/local/bin/process_fts_updates":
    ensure => file,
    owner => "root",
    group => "root",
    mode => 755,
    source => "puppet:///modules/zulip/postgresql/process_fts_updates",
  }

  file { "/etc/supervisor/conf.d/zulip_db.conf":
    require => Package[supervisor],
    ensure => file,
    owner => "root",
    group => "root",
    mode => 644,
    source => "puppet:///modules/zulip/supervisor/conf.d/zulip_db.conf",
    notify => Service[supervisor],
  }
}
