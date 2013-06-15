require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $luser,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::luser}"
  ]
}

File {
  group => 'staff',
  owner => $luser
}

Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => Class['git'],
  config   => {
    'credential.helper' => "${boxen::config::bindir}/boxen-git-credential"
  }
}

Service {
  provider => ghlaunchd
}

Homebrew::Formula <| |> -> Package <| |>

node default {
  # core modules, needed for most things
  include dnsmasq
  include git
  include hub

  # fail if FDE is not enabled
  if $::root_encrypted == 'no' {
    fail('Please enable full disk encryption and try again')
  }

  # default ruby versions
  include ruby::1_8_7
  include ruby::1_9_2
  include ruby::1_9_3
  include ruby::2_0_0

  include iterm2::stable
  include ohmyzsh

  class { 'sublime-text2':
    user => 'nicolamoretto',
    source => 'http://c758482.r82.cf2.rackcdn.com/Sublime%20Text%202.0.1.dmg',
    cmdLine => true,
    plugins => []
  }

  # common, useful packages
  package {
    [
      'ag',
      'findutils',
      'gnu-tar'
    ]:
  }

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }

  file { "/Users/nicolamoretto/.zshrc":
    mode => 644,
    owner => 'nicolamoretto',
    group => staff,
    source => "/opt/boxen/repo/.zshrc"
  }
  #exec { "chsh -s $(which zsh)":
  #  logoutput => true,
  #  subscribe => File["/Users/nicolamoretto/.zshrc"],
  #  refreshonly => true,
  #  user => $luser
  #}
}
