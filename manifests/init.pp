# = Class: adcli
#
# This is the main adcli class
#
#
# == Parameters
#
# Standard class parameters
# Define the general class behaviour and customizations
#
# [*audit_only*]
#   Set to 'true' if you don't intend to override existing configuration files
#   and want to audit the difference between existing files and the ones
#   managed by Puppet. Default: false
#
# [*join_domain*]
#   Set to 'true' to join machine to the domain
#   Default: false
#
# [*my_class*]
#   Name of a custom class to autoload to manage module's customizations
#   If defined, adcli class will automatically "include $my_class"
#
# [*noops*]
#   Set noop metaparameter to true for all the resources managed by the module.
#   Basically you can run a dryrun for this specific module if you set
#   this to true. Default: undef
#
# [*remove_package*]
#   Set to 'true' to remove all the resources installed by the module
#   Default: false
#
# [*version*]
#   The package version, used in the ensure parameter of package type.
#   Default: present. Can be 'latest' or a specific version number.
#   Note that if the argument absent (see below) is set to true, the
#   package is removed, whatever the value of version parameter.
#
# Optional class parameters
#
# [*computer_name*]
#   The short hostname to use when creating a computer object for this host in
#    Active Directory. Default: current shortname of this host.
#
# [*domain_controller*]
#   Connect to a specific domain controller. If not specified then an appropriate
#   domain controller is automatically discovered.
#
# [*domain_ou*]
#   Destination of the computer object that will be created upon joining.
#   Default: undef, meaning AD will place it in YOURAD/Computers
#
# [*os_name*]
#   Computer object comment field. Default: undef
#
# [*os_service_pack*]
#   Computer object comment field. Default: undef
#
# [*os_version*]
#   Computer object comment field. Default: undef
#
# [*pre_create_computer_obj*]
#   Checks to see if the object exists, if it does it reset the account
#   if it doesn't it precreates the object in the desired OU set in *domain_ou*.
#   Default: false
#
# [*replication_wait*]
#   Number of seconds to delay exiting this module. Performing operations on
#   the newly-created computer object tend to fail it you don't wait at least
#   90 seconds. Default: 90
#
# [*service_names*]
#   Kerberos service principals to add. Default: undef
#
# [*unjoin_domain*]
#   Set to 'true' to unjoins and deletes computer from the Domain.
#   Default: false
#
# [*user_principal*]
#   Set user principal name when machine is joined to the Domain. If
#   nothing is set COMPUTERNAME$@REALM is used.
#   Default: undef
#
# [*uppercase_hostname*]
#   Whether we should present our hostname in uppercase when joining AD.
#   Useful for maintaining consistency with clients that joined AD via Samba
#   which insists on using uppercase hostnames. Default: false
#
class adcli (
  $audit_only           = false,
  $external_service     = '',
  $join_domain          = false,
  $my_class             = '',
  $noops                = undef,
  $remove_package       = false,
  $version              = 'present',

  # required parameters
  $domain_name          = '',
  $host_fqdn            = $::fqdn,
  $user_name            = '',
  $user_password        = '',

  # optional parameters
  $computer_name            = $::hostname,
  $domain_controller        = undef,
  $domain_ou                = undef,
  $os_name                  = undef,
  $os_service_pack          = undef,
  $os_version               = undef,
  $pre_create_computer_obj  = false,
  $replication_wait         = '90',
  $service_names            = undef,
  $unjoin_domain            = false,
  $user_principal           = undef,
  $uppercase_hostname       = false,
  ) inherits adcli::params {

  ###############################################
  ### Check certain variables for consistency ###
  ###############################################
  if $adcli::join_domain {
    if empty($adcli::domain_name) {
      fail('adcli::domain_name is required, but an empty string was given')
    }
    if empty($adcli::host_fqdn) {
      fail('adcli::host_fqdn is required, but an empty string was given')
    }
    if empty($adcli::user_name) {
      fail('adcli::user_name is required, but an empty string was given')
    }
    if empty($adcli::user_password) {
      fail('adcli::user_password is required, but an empty string was given')
    }
    if $adcli::pre_create_computer_obj {
      if empty($adcli::domain_ou) {
        fail('adcli::domain_ou is required if pre_create_computer_obj is set')
      }
    }
    if $adcli::unjoin_domain {
      fail('adcli::join_domain and adcli::unjoin_domain cannot both be set to true')
    }
  }

  #################################################
  ### Definition of modules' internal variables ###
  #################################################
  # Variables defined in adcli::params
  $package=$adcli::params::package

  # Variables that apply parameters behaviours
  $manage_package = $adcli::remove_package ? {
    true  => 'absent',
    false => $adcli::version,
  }

  $manage_audit = $adcli::audit_only ? {
    true  => 'all',
    false => undef,
  }

  $manage_external_service = $adcli::external_service ? {
    ''      => undef,
    default => Service[$adcli::external_service]
  }

  if empty($adcli::user_principal) {
    $manage_user_principal = inline_template("--user-principal=<%= @hostname.upcase %>$@<%= @domain_name.upcase %>")
  } else {
    validate_string($adcli::user_principal)
    $manage_user_principal = $adcli::user_principal
  }

  #######################################
  ### Resources managed by the module ###
  #######################################
  package { $adcli::package:
    ensure => $adcli::manage_package,
    noop   => $adcli::noops,
  }

  #######################################
  ### Assemble a giant exec statement ###
  #######################################
  $exec_base_begin = "/bin/bash -c '/bin/echo -n ${adcli::user_password} | /usr/sbin/adcli"

  if $adcli::computer_name {
    validate_string($adcli::computer_name)
    if $adcli::uppercase_hostname {
        $exec_cn = inline_template("--computer-name=<%= @hostname.upcase %>")
    } else {
        $exec_cn = "--computer-name=${adcli::computer_name}"
    }
  }

  if $adcli::join_domain {
    $exec_base_action = 'join'
    $exec_base_end = "--domain=${adcli::domain_name} --host-fqdn=${adcli::host_fqdn} --login-user=${adcli::user_name}"
  }

  if $adcli::unjoin_domain {
    $exec_base_action = 'delete-computer'
    $exec_base_end = "--domain=${adcli::domain_name} ${adcli::host_fqdn} --login-user=${adcli::user_name} && rm /etc/krb5.keytab"
  }

  if $domain_controller {
    validate_string($domain_ou)
    $exec_doc = "--domain-controller=\"${adcli::domain_controller}\""
  }

  if $domain_ou {
    validate_string($domain_ou)
    $exec_dou = "--domain-ou=\"${adcli::domain_ou}\""
  }

  if $os_name {
    validate_string($os_name)
    $exec_osn = "--os-name=\"${adcli::os_name}\""
  }

  if $os_service_pack {
    validate_string($os_service_pack)
    $exec_sp = "--os-service-pack=\"${adcli::os_service_pack}\""
  }

  if $os_version {
    validate_string($os_version)
    $exec_osv = "--os-version=\"${adcli::os_version}\""
  }

  if $service_names {
    validate_array($service_names)

    # Guess who suggested inline templates to work around
    # the lack of iteration in pre-Future Parser(tm) Puppet?
    # Again? Riley. Thanks, Riley.
    $exec_sns = inline_template("<% @service_names.each do |service_name| %> --service-name=<%= service_name %><% end %>")
  }

  #######################################
  ### Joins computer to the Domain    ###
  ### if enabled                      ###
  #######################################
  if $join_domain {

    #######################################
    ### Pre-creates computer object if  ###
    ### enabled                         ###
    #######################################
    if $pre_create_computer_obj {
      # You are not seeing things; we need that trailing single quote there
      $preexec = "${exec_base_begin} preset-computer --domain=${adcli::domain_name} ${adcli::host_fqdn} --login-user=${adcli::user_name} ${manage_user_principal} ${exec_doc} ${exec_dou} ${exec_osn} ${exec_osv} ${exec_sp}'"
      exec { "adcli_preexec_for_${adcli::computer_name}_on_${adcli::domain_name}":
        command => $preexec,
        require => Package[$adcli::package],
        before  => Exec["adcli_join_domain_${adcli::domain_name}"],
        unless  => "${exec_base_begin} reset-computer ${exec_base_end} ",
      }
      exec { "adcli_pre_create_sleep_${adcli::domain_name}":
        command     => "/bin/sleep ${replication_wait}",
        subscribe   => Exec["adcli_preexec_for_${adcli::computer_name}_on_${adcli::domain_name}"],
        refreshonly => true,
      }
    }

    # You are not seeing things; we need that trailing single quote there
    $adcli_exec = "${exec_base_begin} ${exec_base_action} ${exec_base_end} ${manage_user_principal} ${exec_cn} ${exec_doc} ${exec_dou} ${exec_osn} ${exec_osv} ${exec_sp} ${exec_sns}'"
    exec { "adcli_join_domain_${adcli::domain_name}":
      command => $adcli_exec,
      creates => '/etc/krb5.keytab',
      require => Package[$adcli::package],
      notify  => $adcli::manage_external_service,
    }
    exec { "adcli_join_domain_sleep_${adcli::domain_name}":
      command     => "/bin/sleep ${replication_wait}",
      subscribe   => Exec["adcli_join_domain_${adcli::domain_name}"],
      refreshonly => true,
    }
  }

  #######################################
  ### Unjoins and deletes computer    ###
  ### from the Domain if enabled      ###
  #######################################
  if $unjoin_domain {
    # You are not seeing things; we need that trailing single quote there
    $adcli_unjoin_exec = "${exec_base_begin} ${exec_base_action} ${exec_doc} ${exec_base_end}'"
    exec { "adcli_unjoin_domain_${adcli::domain_name}":
      command => $adcli_unjoin_exec,
      onlyif  => '/bin/ls -l /etc/krb5.keytab',
      require => Package[$adcli::package],
    }
    exec { "adcli_unjoin_domain_sleep_${adcli::domain_name}":
      command     => "/bin/sleep ${replication_wait}",
      subscribe   => Exec["adcli_unjoin_domain_${adcli::domain_name}"],
      refreshonly => true,
    }
  }

  #######################################
  ### Optionally include custom class ###
  #######################################
  if $adcli::my_class {
    include $adcli::my_class
  }
}