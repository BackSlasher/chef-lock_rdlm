# Executes my functions on the RDLM server

ruby_block 'create-and-delete' do
  block do
    mutex_name='blob'
    mu = MutexRDLM.mutex_lock("http://localhost:#{node['mutex_rdlm']['port']}",mutex_name,'nonya',5,300)
    raise 'Mutex missing' unless MutexRDLM.mutex_check(mu)
    MutexRDLM.mutex_release(mu)
    raise 'Mutex lingers' if MutexRDLM.mutex_check(mu)
  end
end

ruby_block 'test-with-mutex' do
  block do
    node.default['mutex_rdlm']['hostname']='localhost'
    a=3
    MutexRDLM.with_mutex(node,'blo') {a=4}
    raise 'did not run via mutex' unless a==4
  end
end
