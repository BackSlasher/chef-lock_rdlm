# cookbook: mutex_rdlm
# library: helpers.rb
#
# Author: Nitzan
# GPLv2
#
# Assign a unique value to a node's attribute

module MutexRDLM

  # Locks a mutex. Returns a mutex object (used to release it) if successful
  def mutex_lock(server,mutex_name,wait,lifetime)
    require 'net/http'
    uri = URI(server)
    resp = Net::HTTP.new(uri.host).get(uri)
    #TODO throw if not 2XX
    obj = resp['Location']
    return obj
  end

  def mutex_release(mutex_object)

  end
end
