#
# Cookbook Name:: mutex_identity
# Recipe:: server
#
# GPLv2, Nitzan Raz
#
# Installs and configures a simple RDLM daemon

user 'rdlm' do
  shell '/bin/false'
  system true
end

python_package 'rdlm'

template '/etc/init.d/rdlm' do
  source 'rdlm-init.sh'
  notifies :restart,'service[rdlm]'
  variables ({
    port: node['mutex_identity']['port'],
    user: 'rdlm',
  })
end

service 'rdlm' do
  action [:enable, :start]
end
