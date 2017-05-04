#install default packages

class base(
  $ensure = 'present',
){ 

  exec { 'base-update-apt':
    path      => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/', '/usr/local/bin/', '/usr/local/sbin/'],
    command   => 'apt-get update > /dev/null 2>&1',
    logoutput => on_failure,
  }

  $packages = [
    'nano',       
    'curl',
    'wget',    
    'zip',
    'unzip',
    'tar',
    'git']

  package { $packages:
    ensure => $package_ensure,
    require => Exec['base-update-apt'],
  }

  define printPackages{
    notify { $name: 
      message => "Installed package: ${name}",
    }
  }
  printPackages{ $packages:}

}
