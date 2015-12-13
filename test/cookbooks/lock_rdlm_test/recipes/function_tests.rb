# Executes my functions on the RDLM server

ruby_block 'create-and-delete' do
  block do
    lock_name='blob'
    mu = MutexRDLM.lock_acquire("http://localhost:#{node['lock_rdlm']['port']}",lock_name,'nonya',5,300)
    raise 'Mutex missing' unless MutexRDLM.lock_check(mu)
    MutexRDLM.lock_release(mu)
    raise 'Mutex lingers' if MutexRDLM.lock_check(mu)
  end
end

ruby_block 'test-with-lock' do
  block do
    node.default['lock_rdlm']['hostname']='localhost'
    a=3
    MutexRDLM.with_lock(node,'blo') {a=4}
    raise 'did not run via lock' unless a==4
  end
end
