# adcli

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with adcli](#setup)
    * [What adcli affects](#what-adcli-affects)
    * [Beginning with adcli](#beginning-with-adcli)
4. [Basic Usage - Configuration options and additional functionality](#basic-usage)
5. [Usage - Configuration options and additional functionality](#usage)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for contributing to the module](#development)

## Overview

The adcli module lets you use Puppet to perform actions in an Active Directory domain.

## Module Description

Adcli (Active Directory Command Line Interface) is a management tool available on Debian, Ubuntu, Centos, Redhat and several other operating systems. The adcli module provides a series of classes, and defines to help you automate performing actions on an Active Directory domain.

## Setup

### What adcli affects

* Your system's `/etc/krb5.keytab` file
* Which is used by mit or heimdal krb5 via `/etc/krb5.conf`
* Its recommend to also configure these (mit or heimdal krb5):

### Beginning with adcli

To use the adcli module with default parameters, declare the `adcli` class.

~~~puppet
include adcli
~~~

## Basic Usage

### Install a specific version of adcli package

~~~puppet
class { 'adcli':
  version => '1.0.1',
}
~~~

### Disable adcli service.

~~~puppet
class { 'adcli':
  disable => true,
}
~~~

### Remove adcli package

~~~puppet
class { 'adcli':
  absent => true,
}
~~~

### Enable auditing

Without without making changes on existing adcli configuration files

~~~puppet
class { 'adcli':
  audit_only => true,
}
~~~

### Module dry-run:

Do not make any change on all the resources provided by the module.

~~~puppet
class { 'adcli':
  noops => true
}
~~~

### Remove adcli package
~~~puppet
class { 'adcli':
  absent => true,
}
~~~

## Usage

### Join an AD domain.

If your site is using hiera you can override these values.

~~~puppet
class { 'adcli':
  user_name               => 'administrator',
  user_password           => 'password',
  domain_name             => 'mydomain.local',
  domain_ou               => 'OU=Computers,OU=Dept,DC=mydomain,DC=local',
  domain_controller       => 'ad.mydomain.local'
  join_domain             => true,
  os_name                 => $::lsbdistid,
  os_version              => $::lsbdistrelease,
  service_names           => ['host','nfs' ,'cifs'],
  require                 => Class['mit_krb5'],
}
~~~

### ReJoin an AD domain.

If the machine is already joined to AD it can be reset and a computer object can be precreate in AD before joining the computer. Also if your site is using hiera you can override these values.

~~~puppet
class { 'adcli':
  user_name               => 'administrator',
  user_password           => 'password',
  pre_create_computer_obj => true,
  domain_name             => 'mydomain.local',
  domain_ou               => 'OU=Computers,OU=Dept,DC=mydomain,DC=local',
  domain_controller       => 'ad.mydomain.local'
  join_domain             => true,
  os_name                 => $::lsbdistid,
  os_version              => $::lsbdistrelease,
  service_names           => ['host','nfs' ,'cifs'],
  require                 => Class['mit_krb5'],
}
~~~

### Remove machine from AD domain.

If your machine is already joined to AD it can be removed by the following. Also if your site is using hiera you can override these values.

~~~puppet
class { 'adcli':
  user_name               => 'administrator',
  user_password           => 'password',
  domain_name             => 'mydomain.local',
  domain_controller       => 'ad.mydomain.local'
  unjoin_domain           => true,
}
~~~

### Overrides Usage

Use custom sources for main config file

~~~puppet
class { 'adcli':
  source => [ "puppet:///modules/example42/adcli/adcli.conf-${hostname}" , "puppet:///modules/example42/adcli/adcli.conf" ],
}
~~~

Use custom source directory for the whole configuration dir

~~~puppet
class { 'adcli':
  source_dir       => 'puppet:///modules/example42/adcli/conf/',
  source_dir_purge => false, # Set to true to purge any existing file not present in $source_dir
}
~~~

Use custom template for main config file. Note that template and source arguments are alternative.

~~~puppet
class { 'adcli':
  template => 'example42/adcli/adcli.conf.erb',
}
~~~

Automatically include a custom subclass

~~~puppet
class { 'adcli':
  my_class => 'example42::my_adcli',
}
~~~

## Limitations

This module is tested and officially supported on Centos 7, Debian 7 and Ubuntu 12.04, and 14.04. Testing on other platforms has been light and cannot be guaranteed. Its suggested to use this module inconjuction with mit or heimdal krb5.

## Development

Community contributions are essential for keeping them great. We can't access the huge number of platforms and myriad hardware, software, and deployment configurations that Puppet is intended to serve. We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

For more information, see our [module contribution guide.](https://docs.puppetlabs.com/forge/contributing.html)

To see who's already involved, see the [list of contributors.](https://github.com/sfu-rcg/puppet-adcli/graphs/contributors)