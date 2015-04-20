
if node[:platform] == 'ubuntu' and  node[:platform_version].to_f >= 14.04
  override[:apache][:mpm] = 'prefork'
end

default[:icinga2][:classic_ui][:enable] = false
default[:icinga2][:web2][:enable] = true
default[:icinga2][:web2][:db_name] = 'icinga_web'
default[:icinga2][:ido][:load_schema] = false
default[:icinga2][:ido][:db_host] = '127.0.0.1'
default[:icinga2][:disable_conf_d] = true
default[:mysql][:server_root_password] = "Ch4ng3me"
default[:icinga2][:ignore_version] = true

default['monitoring-icinga'][:user] = "admin"
default['monitoring-icinga'][:password] = "admin"
