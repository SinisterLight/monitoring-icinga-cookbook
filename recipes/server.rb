#
# Cookbook Name:: monitoring-icinga
# Recipe:: server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'monitoring-icinga::_mysql'

include_recipe 'icinga2::server'

begin
  t = resources(:template => ::File.join(node['apache']['dir'], 'conf-available', 'icinga2-web2.conf'))
  t.source "apache.vhost.icinga2_web2.erb"
  t.cookbook "monitoring-icinga"
rescue Chef::Exceptions::ResourceNotFound
  Chef::Log.warn "could not find template apache.vhost.icinga2_web2.conf to modify"
end

execute "load #{node[:icinga2][:ido][:db_name]} schema" do
  command "\
    mysql -h 127.0.0.1\
    -u #{node[:icinga2][:ido][:db_user]}\
    -p#{node[:icinga2][:ido][:db_password]}\
    #{node[:icinga2][:ido][:db_name]} < /usr/share/icinga2-ido-mysql/schema/mysql.sql \
    && touch /etc/icinga2/schema_loaded_ido_mysql"
  creates '/etc/icinga2/schema_loaded_ido_mysql'
end

execute "load #{node[:icinga2][:web2][:db_name]} schema" do
  command "\
    mysql -h 127.0.0.1\
    -u #{node[:icinga2][:ido][:db_user]}\
    -p#{node[:icinga2][:ido][:db_password]}\
    #{node[:icinga2][:web2][:db_name]} < #{node[:icinga2][:web2][:web_root]}/etc/schema/mysql.schema.sql \
    && touch /etc/icingaweb2/schema_loaded_mysql"
  creates "/etc/icingaweb2/schema_loaded_mysql"
end

file "/etc/php5/apache2/conf.d/timezone.ini" do
  content "date.timezone=DateTimeZone::UTC"
end

icinga2_idomysqlconnection 'ido-mysql' do
  library  'db_ido_mysql'
  host     '127.0.0.1'
  user     node[:icinga2][:ido][:db_user]
  password node[:icinga2][:ido][:db_password]
  database node[:icinga2][:ido][:db_name]
end

%w(authentication.ini config.ini roles.ini).each do |file|
  template "#{node[:icinga2][:web2][:conf_dir]}/#{file}" do
    user node[:apache][:user]
    group node[:apache][:user]
    source "#{file}.erb"
  end
end

template "#{node[:icinga2][:web2][:conf_dir]}/resources.ini" do
  user node[:apache][:user]
  group node[:apache][:user]
  source "resources.ini.erb"
  variables(
    user:     node[:icinga2][:ido][:db_user],
    password: node[:icinga2][:ido][:db_password],
    ido_db:   node[:icinga2][:ido][:db_name],
    web2_db:  node[:icinga2][:web2][:db_name]
  )
end

%w(enabledModules modules modules/monitoring).each do |dir|
  directory "#{node[:icinga2][:web2][:conf_dir]}/#{dir}" do
    user node[:apache][:user]
    group node[:apache][:user]
  end
end

%w(backends.ini config.ini instances.ini).each do |file|
  template "#{node[:icinga2][:web2][:conf_dir]}/modules/monitoring/#{file}" do
    user node[:apache][:user]
    group node[:apache][:user]
    source "web2/monitoring/#{file}.erb"
  end
end

link "#{node[:icinga2][:web2][:conf_dir]}/enabledModules/monitoring"do
  user node[:apache][:user]
  group node[:apache][:user]
  to "#{node[:icinga2][:web2][:web_root]}/modules/monitoring"
  mode "777"
end


execute "create icinga user" do
  command <<-EOH
    mysql -h 127.0.0.1 -u #{node[:icinga2][:ido][:db_user]} -p#{node[:icinga2][:ido][:db_password]}\
    -e "INSERT INTO #{node[:icinga2][:web2][:db_name]}.icingaweb_user (name, active, password_hash) VALUES ('#{node['monitoring-icinga'][:user]}', 1, \\"$(openssl passwd -1 #{node['monitoring-icinga'][:password]})\\");"
  EOH
  not_if "mysql -h 127.0.0.1 -u #{node[:icinga2][:ido][:db_user]} -p#{node[:icinga2][:ido][:db_password]} -e \"select * from icinga_web.icingaweb_user where name='#{node['monitoring-icinga'][:user]}'\" | grep -w #{node['monitoring-icinga'][:user]}"
end
