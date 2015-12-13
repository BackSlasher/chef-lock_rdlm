# cookbook: lock_rdlm
# library: helpers.rb
#
# Author: Nitzan
# GPLv2
#
# Assign a unique value to a node's attribute

module MutexRDLM

  # Locks a lock. Returns a lock object (used to release it) if successful
  def self.lock_acquire(server,lock_name,client_name,wait,lifetime)
    require 'net/http'
    uri = URI(server)
    uri.path="/locks/#{lock_name}"
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

  def self.lock_check(lock_object)
    require 'net/http'
    require 'json'
    uri = URI(lock_object)
    resp = Net::HTTP.new(uri.host,uri.port).get(uri)
    if resp.code == '404'
      return nil # no such lock
    elsif resp.code == '200'
      return JSON.parse(resp.body)
    else
      raise "Unknown response #{resp.code}" #TODO use my exception
    end
  end

  def self.lock_release(lock_object)
    require 'net/http'
    uri = URI(lock_object)
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

  def self.with_lock(node,lock_resource, lock_url: nil, lock_wait: nil, lock_lifetime: nil)

    unless lock_url then
      url_blocks = node['lock_rdlm'].values_at(:scheme,:hostname,:port)
      raise 'cannot deduce lock server. Please specify one using attributes or function arguments' if url_blocks.any?{|v|!v} #TODO use my exception
      lock_url = "#{url_blocks[0]}://#{url_blocks[1]}:#{url_blocks[2]}"
    end

    lock_wait||=node['lock_rdlm']['wait']
    lock_lifetime||=node['lock_rdlm']['lifetime']

    # Start working
    lock=lock_acquire(lock_url,
               _normalize_name(lock_resource),
               _normalize_name(node.name),
               lock_wait,lock_lifetime)
    begin
      yield if block_given?
    ensure # Always delete lock
      lock_release(lock)
    end
  end
end
