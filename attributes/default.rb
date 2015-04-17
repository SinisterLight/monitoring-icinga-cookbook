
if node['platform'] == 'ubuntu' and  node['platform_version'].to_f >= 14.04
  override['apache']['mpm'] = 'prefork'
end

override['icinga2']['classic_ui']['enable'] = false
override['icinga2']['web2']['enable'] = true
