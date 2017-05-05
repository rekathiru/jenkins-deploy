#jenkins class
class jenkins(
  $owner   = 'root',
  $group   = 'root',
  $repo_url	   = 'https://github.com/rekathiru',
  $repo_name = "jenkins-deploy",
){
  include base, java
  $jenkins_home="/var/jenkins_home"
  $jenkins_version="2.46.2"
  $jenkins_sha="aa7f243a4c84d3d6cfb99a218950b8f7b926af7aa2570b0e1707279d464472c7"
  $jenkins_url="https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${jenkins_version}/jenkins-war-${jenkins_version}.war"
  $jenkins_user="jenkins"
  $jenkins_group="jenkins"
  
  group { 'jenkins':
      ensure => 'present',
      gid    => '1200',
  }

  user { 'jenkins':
       ensure           => 'present',
       gid              => '1200',
       home             =>  $jenkins_home,
       uid              => '1200',
       shell            => '/bin/bash',
       require		=> Group["jenkins"],
  }
  
  $directories = [
	'/usr/share/jenkins',
	'/usr/share/jenkins/ref/',
	"${jenkins_home}"
  ]  

  file { $directories:
    ensure => 'directory',
    owner     => $jenkins_user,
    group      => $jenkins_group,
    require     => User["${jenkins_user}" ],
    recurse    => true,
  }

  exec {
     'Install Jenkins':
      path      => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      cwd       => "/usr/share/jenkins",
      command   => "curl -fsSL ${jenkins_url} -o /usr/share/jenkins/jenkins.war && echo \"${jenkins_sha}  /usr/share/jenkins/jenkins.war\" | sha256sum -c -",
      logoutput => 'on_failure',
      require => [
	           File[$directories], 
		   Vcsrepo["${jenkins_home}/${repo_name}"]
                 ];

      'Start Jenkins':
      path      => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      cwd       => "${jenkins_home}/${repo_name}/jenkins-scripts",
      environment => [ "JENKINS_HOME=${jenkins_home}" ],
      command   => "nohup ./jenkins.sh > jenkins.out&",
      user        => $jenkins_user,
      logoutput => 'on_failure',
      require => Exec['Install Jenkins'];
  
      'Set Jenkins home permission':
      path      => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      cwd       => $jenkins_home,
      command   => "chown -R ${jenkins_user} $jenkins_home; chmod -R 755 $jenkins_home",
      require   => Exec['copy Configurations', 'copy Plugins'];

      'wait for jenkins':
      path      => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      command => "sleep 45",
      require => Exec["Start Jenkins"];

      'install Plugins':
      path      => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      cwd       => "${jenkins_home}/${repo_name}/jenkins-scripts",
      environment => [ "JENKINS_HOME=${jenkins_home}" ],
      command   => "bash install-plugins.sh github maven-plugin",
      user        => $jenkins_user,
      logoutput => 'on_failure',
      require => Exec["wait for jenkins"];

       'copy Configurations':
      path      => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      cwd       => "${jenkins_home}",
      command   => "cp -r jenkins-deploy/jenkins/* .;cp -r jenkins-deploy/jenkins/jobs/* ./jobs/;cp -r jenkins-deploy/jenkins/users/* ./users/",
      user        => $jenkins_user,
      logoutput => 'on_failure',
      require => Exec["copy Plugins"];


       'copy Plugins':
      path      => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      cwd       => "${jenkins_home}",
      command   => "cp -r /usr/share/jenkins/ref/plugins/* ./plugins/",
      user        => $jenkins_user,
      logoutput => 'on_failure',
      require => Exec["install Plugins"];

      "restart jenkins":
      path      => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      cwd       => "${jenkins_home}/${repo_name}/jenkins-scripts",
      environment => [ "JENKINS_HOME=${jenkins_home}" ],
      command   => "nohup ./jenkins-restart.sh > jenkins-restart.out&",
      user        => $jenkins_user,
     # logoutput => 'on_failure',
      require => Exec['Set Jenkins home permission'];



  }

  vcsrepo { "${jenkins_home}/${repo_name}":
        ensure   => latest,
        owner    => $jenkins_user,
        group    => $jenkins_group,
        provider => git,
        source   => "${repo_url}/${repo_name}.git",
        revision => 'master',
	require     => User["${jenkins_user}"],
    }


  # install base before java before jenkins before agent
  Class['base'] -> Class['java'] -> Class['jenkins']
}
