# cookbook: mutex_rdlm
# library: helpers.rb
#
# Author: Nitzan
# GPLv2
#
# Helper methods for mutexing

module MutexRDLM
  # get value from node
  def _get_value(node,assignment_path)
    node.attributes.merged_attributes(*assignment_path)
  end

  # Set a value in a vivid hash/array, recursively
  def _vivid_set(vivid,assignment_path,value)
    if assignment_path.length==1
      vivid[assignment_path.first]=value
    else
      _vivid_set(vivid[assignment_path.first],assignment_path.drop(1))
    end
  end

  # set value in node's normal
  def _set_normal(node,assignment_path,value)
    _vivid_set(node.normal,assignment_path,value)
  end

  # set value in node's server
  def _set_server(node,assignment_path,value)
    s_node = Chef::Node.load(node.name)
    _set_normal(s_node,assignment_path,value)
    s.save
  end
end
