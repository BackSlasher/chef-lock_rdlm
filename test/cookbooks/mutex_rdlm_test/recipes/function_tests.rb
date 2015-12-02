# Executes my functions on the RDLM server

ruby_block 'test-with-mutex' do
  block do
    node.default['mutex_rdlm']['hostname']='localhost'
    a=3
    MutexRDLM.with_mutex(node,'blo') {a=4}
    raise 'did not run via mutex' unless a==4
  end
end
