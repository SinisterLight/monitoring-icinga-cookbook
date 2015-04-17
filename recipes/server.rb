#
# Cookbook Name:: monitoring-icinga
# Recipe:: server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'icinga2::server'

begin
  t = resources(:template => ::File.join(node['apache']['dir'], 'conf-available', 'icinga2-web2.conf'))
  t.source "apache.vhost.icinga2_web2.erb"
  t.cookbook "monitoring-icinga"
rescue Chef::Exceptions::ResourceNotFound
  Chef::Log.warn "could not find template apache.vhost.icinga2_web2.conf to modify"
end
