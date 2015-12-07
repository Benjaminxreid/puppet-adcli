##2015-12-07 - Release
###Summary

This release only includes bug fixes.

####Bugfixes
- Changed parmenter name from absent/isabsent to remove_package;
- Removed dependency on mit_krb5 as others could be used such as Heimdal.
- Changed stdlib dependency to 4.2.

##2015-11-10 - Release
###Summary

This release includes a few bug fixes.

####Features
- Added an `domain_controller, pre_create_computer_obj, unjoin_domain` parameter for more finit control
- Added more documentation

####Bugfixes
- Fixed refresh and subscribe on exec statement wait statements;
- Fixed join_domain parameter.
- Linted code, ignouring inline_template's

##2015-03-23 - Release
###Summary

This release includes new features only.

####Features
- Add replication_wait parameter to prevent module from exiting before newly-create computer objects have propagated across all domain controllers

##2015-02-12 - Release
###Summary

Forked module from mburger/puppet-adcli

####Features
- Added extra parameters (domain_ou, os_name, os_version, os_service_pack, service_names)
- Split up assembly of exec statement.