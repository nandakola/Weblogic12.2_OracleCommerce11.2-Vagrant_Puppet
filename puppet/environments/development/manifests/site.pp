#
# one machine setup with weblogic 12.2.1
# needs jdk7, orawls, orautils, fiddyspence-sysctl, erwbgy-limits puppet modules
#
Package{allow_virtual => false,}

node 'admin.example.com' {

  include os
  include ssh
  include java
  include orawls::weblogic
  include orautils, jdk7::urandomfix
  # include weblogic
  include bsu
  include fmw
  include opatch
  include domains
  include nodemanager, startwls, userconfig
  include security
  include basic_config
  include datasources
  include pack_domain
  include atg

  Class[java] -> Class[orawls::weblogic]
  # Jdk7::Install7  <| |> -> Orawls::Weblogic_type <| |>

}

# operating settings for Middleware
class os {

  $default_params = {}
  $host_instances = hiera('hosts', {})
  create_resources('host',$host_instances, $default_params)

  # exec { "create swap file":
  #   command => "/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=8192",
  #   creates => "/var/swap.1",
  # }

  # exec { "attach swap file":
  #   command => "/sbin/mkswap /var/swap.1 && /sbin/swapon /var/swap.1",
  #   require => Exec["create swap file"],
  #   unless => "/sbin/swapon -s | grep /var/swap.1",
  # }

  # #add swap file entry to fstab
  # exec {"add swapfile entry to fstab":
  #   command => "/bin/echo >>/etc/fstab /var/swap.1 swap swap defaults 0 0",
  #   require => Exec["attach swap file"],
  #   user => root,
  #   unless => "/bin/grep '^/var/swap.1' /etc/fstab 2>/dev/null",
  # }

  service { iptables:
        enable    => false,
        ensure    => false,
        hasstatus => true,
  }

  group { 'dba' :
    ensure => present,
  }

  # http://raftaman.net/?p=1311 for generating password
  # password = oracle
  user { 'oracle' :
    ensure     => present,
    groups     => 'dba',
    shell      => '/bin/bash',
    password   => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home       => "/home/oracle",
    comment    => 'wls user created by Puppet',
    managehome => true,
    require    => Group['dba'],
  }

  $install = [ 'binutils.x86_64','unzip.x86_64']


  # package { $install:
  #   ensure  => present,
  # }

  class { 'limits':
    config => {
               '*'       => {  'nofile'  => { soft => '2048'   , hard => '8192',   },},
               'oracle'  => {  'nofile'  => { soft => '65536'  , hard => '65536',  },
                               'nproc'   => { soft => '2048'   , hard => '16384',   },
                               'memlock' => { soft => '1048576', hard => '1048576',},
                               'stack'   => { soft => '10240'  ,},},
               },
    use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}

}

class ssh {
  require os


  file { "/home/oracle/.ssh/":
    owner  => "oracle",
    group  => "dba",
    mode   => "700",
    ensure => "directory",
    alias  => "oracle-ssh-dir",
  }

  file { "/home/oracle/.ssh/id_rsa.pub":
    ensure  => present,
    owner   => "oracle",
    group   => "dba",
    mode    => "644",
    source  => "/vagrant/ssh/id_rsa.pub",
    require => File["oracle-ssh-dir"],
  }

  file { "/home/oracle/.ssh/id_rsa":
    ensure  => present,
    owner   => "oracle",
    group   => "dba",
    mode    => "600",
    source  => "/vagrant/ssh/id_rsa",
    require => File["oracle-ssh-dir"],
  }

  file { "/home/oracle/.ssh/authorized_keys":
    ensure  => present,
    owner   => "oracle",
    group   => "dba",
    mode    => "644",
    source  => "/vagrant/ssh/id_rsa.pub",
    require => File["oracle-ssh-dir"],
  }
}

class java {
  require os

  $remove = [ "java-1.7.0-openjdk.x86_64", "java-1.6.0-openjdk.x86_64" ]

  # package { $remove:
  #   ensure  => absent,
  # }

  include jdk7

  jdk7::install7{ 'jdk-8u51-linux-x64':
      version                     => "8u51" ,
      full_version                => "jdk1.8.0_51",
      alternatives_priority       => 18001,
      x64                         => true,
      download_dir                => "/var/tmp/install",
      urandom_java_fix            => true,
      rsa_key_size_fix            => true,
      cryptography_extension_file => "jce_policy-8.zip",
      source_path                 => "/software",
  }

  # jdk7::install7{ 'jdk-8u65-linux-x64':
  #     version                     => "8u65" ,
  #     full_version                => "jdk1.8.0_65",
  #     alternatives_priority       => 18001,
  #     x64                         => true,
  #     download_dir                => "/var/tmp/install",
  #     urandom_java_fix            => true,
  #     rsa_key_size_fix            => true,
  #     cryptography_extension_file => "jce_policy-8.zip",
  #     source_path                 => "/software",
  # }

}

# class weblogic {
#   require java
#   $default_params = {}
#   $weblogic_instances = hiera('weblogic_instances', {})
#   create_resources('orawls::weblogic_type',$weblogic_instances, $default_params)
# }

class bsu{
  require orawls::weblogic
  $default_params = {}
  $bsu_instances = hiera('bsu_instances', {})
  create_resources('orawls::bsu',$bsu_instances, $default_params)
}

class fmw{
  require bsu
  $default_params = {}
  $fmw_installations = hiera('fmw_installations', {})
  create_resources('orawls::fmw',$fmw_installations, $default_params)
}

class opatch{
  require fmw, bsu, orawls::weblogic
  $default_params = {}
  $opatch_instances = hiera('opatch_instances', {})
  create_resources('orawls::opatch',$opatch_instances, $default_params)
}

class domains{
  require opatch, orawls::weblogic

  $default_params = {}
  $domain_instances = hiera('domain_instances', {})
  create_resources('orawls::domain',$domain_instances, $default_params)

  $wls_setting_instances = hiera('wls_setting_instances', {})
  create_resources('wls_setting',$wls_setting_instances, $default_params)

}

class nodemanager {
  require domains

  $default_params = {}
  $nodemanager_instances = hiera('nodemanager_instances', {})
  create_resources('orawls::nodemanager',$nodemanager_instances, $default_params)

  $str_version  = hiera('wls_version')
  $domains_path = hiera('wls_domains_dir')
  $domain_name  = hiera('domain_name')

  orautils::nodemanagerautostart{"autostart weblogic":
    version                   => $str_version,
    domain                    => $domain_name,
    domain_path               => "${domains_path}/${domain_name}",
    wl_home                   => hiera('wls_weblogic_home_dir'),
    user                      => hiera('wls_os_user'),
    jsse_enabled              => hiera('wls_jsse_enabled'             ,false),
    custom_trust              => hiera('wls_custom_trust'             ,false),
    trust_keystore_file       => hiera('wls_trust_keystore_file'      ,undef),
    trust_keystore_passphrase => hiera('wls_trust_keystore_passphrase',undef),
  }

}

class startwls {
  require domains, nodemanager

  $default_params = {}
  $control_instances = hiera('control_instances', {})
  create_resources('orawls::control',$control_instances, $default_params)
}

class userconfig{
  require domains, nodemanager, startwls
  $default_params = {}
  $userconfig_instances = hiera('userconfig_instances', {})
  create_resources('orawls::storeuserconfig',$userconfig_instances, $default_params)
}


class security{
  require userconfig
  $default_params = {}
  $user_instances = hiera('user_instances', {})
  create_resources('wls_user',$user_instances, $default_params)

  $group_instances = hiera('group_instances', {})
  create_resources('wls_group',$group_instances, $default_params)

  $authentication_provider_instances = hiera('authentication_provider_instances', {})
  create_resources('wls_authentication_provider',$authentication_provider_instances, $default_params)

  $identity_asserter_instances = hiera('identity_asserter_instances', {})
  create_resources('wls_identity_asserter',$identity_asserter_instances, $default_params)

}

class basic_config{
  require security
  $default_params = {}

  $wls_domain_instances = hiera('wls_domain_instances', {})
  create_resources('wls_domain',$wls_domain_instances, $default_params)

  # subscribe on domain changes
  $wls_adminserver_instances_domain = hiera('wls_adminserver_instances_domain', {})
  create_resources('wls_adminserver',$wls_adminserver_instances_domain, $default_params)

  $machines_instances = hiera('machines_instances', {})
  create_resources('wls_machine',$machines_instances, $default_params)

  $server_instances = hiera('server_instances', {})
  create_resources('wls_server',$server_instances, $default_params)

  # subscribe on server changes
  $wls_adminserver_instances_server = hiera('wls_adminserver_instances_server', {})
  create_resources('wls_adminserver',$wls_adminserver_instances_server, $default_params)

  $server_template_instances = hiera('server_template_instances', {})
  create_resources('wls_server_template',$server_template_instances, $default_params)

}

class datasources{
  require basic_config
  $default_params = {}
  $datasource_instances = hiera('datasource_instances', {})
  create_resources('wls_datasource',$datasource_instances, $default_params)
}

class pack_domain{
  require datasources

  $default_params = {}
  $pack_domain_instances = hiera('pack_domain_instances', $default_params)
  create_resources('orawls::packdomain',$pack_domain_instances, $default_params)
}

class atg{
require java,domains
$user = "oracle"
$group ="dba"
$temp_directory = "/software"
$atg_bin_file = "OCPlatform11.2.bin"
$atg_install_config_file = "installer.properties"
$atg_install_dir ="/opt/oracle/atg"
$atg_home ="/opt/oracle/atg/ATG11.2"
Exec {
        path => [ "/usr/bin", "/bin", "/usr/sbin", "${temp_directory}"]
    }
      file { "fix atg bin permissions" :
            ensure => "present",
            path => "${temp_directory}/${atg_bin_file}",
            owner  => "${user}",
            mode   => "0755"
        }
        ->
        file { "${temp_directory}/${atg_install_config_file}" :
            owner   => "${user}",
            mode    => "0755",
            content => template("atg/${atg_install_config_file}.erb")
        }
        ->
        file { 'atg install folder' :
            path => "${atg_install_dir}",
            ensure => directory,
            owner => "${user}"
        }
        ->
        exec { 'execute atg bin':
            cwd => "${temp_directory}",
            timeout => 0,
            command => "${temp_directory}/./${atg_bin_file} -f ${temp_directory}/${atg_install_config_file} -i silent",
            logoutput => "true",
            creates => "${atg_home}"
        }
        ->
        exec { 'fix atg permissions':
            cwd => "${temp_directory}",
            timeout => 0,
            command => "chown -R ${user}:${group} ${atg_install_dir}"
        }
        ->
        file { "/etc/profile.d/atg.sh":
          content => "export DYNAMO_ROOT=${atg_home} \nexport DYNAMO_HOME=${atg_home}/home \nexport PATH=\$PATH:\$DYNAMO_HOME/bin \n"
        }
}

#exec { "start_mysql":
#	command	=> "su oracle /software/provision.sh",
#  path => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
#  provider => 'shell',
#}
