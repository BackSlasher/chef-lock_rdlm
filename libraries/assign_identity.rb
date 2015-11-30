# cookbook: mutex_rdlm
# library: helpers.rb
#
# Author: Nitzan
# GPLv2
#
# Assign a unique value to a node's attribute

module MutexRDLM
  def assign_identity(node,assignment_path,range,*additional_config)
    # parse config
    mutex_url = additional_config.delete(:mutex_url)
    mutex_wait = additional_config.delete(:mutex_wait)
    mutex_lifetime = additional_config.delete(:mutex_lifetime)
    raise "Unknown options passed: #{additional_config.keys}" if additional_config.keys.any?

    unless mutex_url then
      url_blocks = node['mutex_rdlm'].values_at(:scheme,:hostname,:port)
      raise 'cannot deduce mutex server. Please specify one using attributes or function arguments' if url_blocks.any?{|v|!v}
      mutex_url = "#{url_blocks[0]}://#{url_blocks[1]}:#{url_blocks[2]}"
    end

    mutex_wait||=node['mutex_rdlm']['wait']
    mutex_lifetime=node['mutex_lifetime']['lifetime']

    # Start working
    current_value =  _get_value(node,assignment_path)
    return current_value if current_value # abort if value is already set
    mutex_name = assignment_path.map{|p|p.gsub(/\W|_/,'')}.join
  end
end
