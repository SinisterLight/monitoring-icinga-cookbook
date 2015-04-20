
mysql_service 'default' do
  version '5.6'
  bind_address '0.0.0.0'
  port '3306'
  data_dir '/data'
  initial_root_password node[:mysql][:server_root_password]
  action [:create, :start]
end

execute "create-database-user #{node[:icinga2][:ido][:db_user]}" do
  code = <<-EOH
    mysql -u root -p#{node[:mysql][:server_root_password]} -h 127.0.0.1 -e "select user,host from mysql.user;" | grep #{node[:icinga2][:ido][:db_user]}
  EOH
  command <<-EOH
    mysql -u root -p#{node[:mysql][:server_root_password]} -h 127.0.0.1 -e "CREATE USER '#{node[:icinga2][:ido][:db_user]}' IDENTIFIED BY '#{node[:icinga2][:ido][:db_user]}';"
    mysql -u root -p#{node[:mysql][:server_root_password]} -h 127.0.0.1 -e "GRANT ALL PRIVILEGES ON *.* TO '#{node[:icinga2][:ido][:db_user]}';"
  EOH
  not_if code
end

execute "create-database #{node[:icinga2][:ido][:db_name]}" do
  command "mysql -h 127.0.0.1 -u #{node[:icinga2][:ido][:db_user]} -p#{node[:icinga2][:ido][:db_password]} -e 'create database #{node[:icinga2][:ido][:db_name]};'"
  not_if "mysql -h 127.0.0.1 -u root -p#{node[:mysql][:server_root_password]} -e 'show databases;' | grep -w #{node[:icinga2][:ido][:db_name]}"
end

execute "create-database #{node[:icinga2][:web2][:db_name]}" do
  command "mysql -h 127.0.0.1 -u #{node[:icinga2][:ido][:db_user]} -p#{node[:icinga2][:ido][:db_password]} -e 'create database #{node[:icinga2][:web2][:db_name]};'"
  not_if "mysql -h 127.0.0.1 -u root -p#{node[:mysql][:server_root_password]} -e 'show databases;' | grep -w #{node[:icinga2][:web2][:db_name]}"
end
