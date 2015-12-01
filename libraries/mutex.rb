# cookbook: mutex_rdlm
# library: helpers.rb
#
# Author: Nitzan
# GPLv2
#
# Assign a unique value to a node's attribute

module MutexRDLM

  # Locks a mutex. Returns a mutex object (used to release it) if successful
  def mutex_lock(server,mutex_name,client_name,wait,lifetime)
    require 'net/http'
    uri = URI(server)
    uri.path="/#{mutex_name}"
    require 'json'
    data = {title: client_name, wait: wait, lifetime: lifetime }.to_json
    resp = Net::HTTP.new(uri.host,uri.port).post(uri,data) #TODO is it sending ok?
    if resp.code == '201'
      obj = resp['Location']
      return obj
    elsif resp.code == '408'
      raise 'Lock request timed out' #TODO use my exception
    elsif resp.code == '409'
      raise 'Lock request deleted by admin' #TODO use my exception
    elsif resp.code == '400'
      raise 'Bad lock request' #TODO use my exception
    else
      raise "Unknown response #{resp}" #TODO use my exception
    end
  end

  def mutex_release(mutex_object)
    require 'net/http'
    uri = URI(mutex_object)
    resp = Net::HTTP.new(uri.host,uri.port).get(uri)
    if resp.code == '204'
      return
    elsif resp.code == '404'
      raise 'Lock not found' #TODO use my exception
    else
      raise "Unknown response #{resp}"
    end
  end

  def _normalize_name(source)
    source.gsub(/\W|_/,'')
  end

  def with_mutex(node,mutex_resource,*additional_config)
    # parse config
    mutex_url = additional_config.delete(:mutex_url)
    mutex_wait = additional_config.delete(:mutex_wait)
    mutex_lifetime = additional_config.delete(:mutex_lifetime)
    raise "Unknown options passed: #{additional_config.keys}" if additional_config.keys.any? #TODO use special exception

    unless mutex_url then
      url_blocks = node['mutex_rdlm'].values_at(:scheme,:hostname,:port)
      raise 'cannot deduce mutex server. Please specify one using attributes or function arguments' if url_blocks.any?{|v|!v} #TODO use my exception
      mutex_url = "#{url_blocks[0]}://#{url_blocks[1]}:#{url_blocks[2]}"
    end

    mutex_wait||=node['mutex_rdlm']['wait']
    mutex_lifetime=node['mutex_lifetime']['lifetime']

    # Start working
    mutex=mutex_lock(mutex_url,
               _normalize_name(mutex_resource),
               _normalize_name(node.name),
               mutex_wait,mutex_lifetime)
    begin
      yield if block_given?
    ensure # Always delete mutex
      mutex_release(mutex)
    end
  end
end
