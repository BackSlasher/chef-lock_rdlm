# cookbook: mutex_rdlm
# library: helpers.rb
#
# Author: Nitzan
# GPLv2
#
# Assign a unique value to a node's attribute

module MutexRDLM

  # Locks a mutex. Returns a mutex object (used to release it) if successful
  def self.mutex_lock(server,mutex_name,client_name,wait,lifetime)
    require 'net/http'
    uri = URI(server)
    uri.path="/locks/#{mutex_name}"
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
      raise "Unknown response #{resp.code}" #TODO use my exception
    end
  end

  def self.mutex_release(mutex_object)
    require 'net/http'
    uri = URI(mutex_object)
    resp = Net::HTTP.new(uri.host,uri.port).delete(uri)
    if resp.code == '204'
      return
    elsif resp.code == '404'
      raise 'Lock not found' #TODO use my exception
    else
      raise "Unknown response #{resp.code}"
    end
  end

  def self._normalize_name(source)
    source.gsub(/\W|_/,'')
  end

  def self.with_mutex(node,mutex_resource, mutex_url: nil, mutex_wait: nil, mutex_lifetime: nil)

    unless mutex_url then
      url_blocks = node['mutex_rdlm'].values_at(:scheme,:hostname,:port)
      raise 'cannot deduce mutex server. Please specify one using attributes or function arguments' if url_blocks.any?{|v|!v} #TODO use my exception
      mutex_url = "#{url_blocks[0]}://#{url_blocks[1]}:#{url_blocks[2]}"
    end

    mutex_wait||=node['mutex_rdlm']['wait']
    mutex_lifetime||=node['mutex_rdlm']['lifetime']

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
