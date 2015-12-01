# cookbook: mutex_rdlm
# library: helpers.rb
#
# Author: Nitzan
# GPLv2
#
# Assign a unique value to a node's attribute

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

  def assign_identity(node,assignment_path,range,*additional_config)
    current_value =  _get_value(node,assignment_path)
    return current_value if current_value # abort if value is already set
    # We have to invent a new value
    with_mutex(node,assignment_path.join,*additional_config) do
      # Find existing values
      node_names = Chef::Node.list.keys
      existing_values = node_names.map do |name|
        n = Chef::Node.load(name)
        _get_value(n,assignment_path)
      end
      remaining_range = range - existing_values
      # Choose my value
      if remaining_range.empty?
        raise 'Identity range is exhausted' #TODO use custom exception
      else
        my_value = remaining_range.first
        _set_normal(node,assignment_path,my_value)
        _set_server(node,assignment_path,my_value)
        return my_value
      end
    end
  end
end
