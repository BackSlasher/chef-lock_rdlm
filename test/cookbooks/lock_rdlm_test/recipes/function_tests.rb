# Executes my functions on the RDLM server

ruby_block 'create-and-delete' do
  block do
    lock_name='blob'
    mu = LockRDLM.lock_acquire("http://localhost:#{node['lock_rdlm']['port']}",lock_name,'nonya',5,300)
    raise 'Lock missing' unless LockRDLM.lock_check(mu)
    LockRDLM.lock_release(mu)
    raise 'Lock lingers' if LockRDLM.lock_check(mu)
  end
end

ruby_block 'test-with-lock' do
  block do
    node.default['lock_rdlm']['hostname']='localhost'
    a=3
    LockRDLM.with_lock(node,'blo') {a=4}
    raise 'did not run via lock' unless a==4
  end
end
