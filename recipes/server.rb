
# Cookbook Name:: lock_rdlm
# Recipe:: server
#
# GPLv2, Nitzan Raz
#
# Installs and configures a simple RDLM daemon

user 'rdlm' do
  shell '/bin/false'
  system true
end

python_runtime '2' do
  provider :system
  pip_version true
end

python_package 'rdlm'

template '/etc/init.d/rdlm' do
  mode '755'
  source 'rdlm-init.sh.erb'
  notifies :restart,'service[rdlm]'
  variables ({
    port: node['lock_rdlm']['port'],
    user: 'rdlm',
  })
end

service 'rdlm' do
  action [:enable, :start]
end
