# mutex\_rdlm cookbook

Contains some functions that work with an external mutex server.  
Also supports managing the mutex server using [RDLM](https://github.com/thefab/restful-distributed-lock-manager)

## Supported Platforms

For clients: Nothing native, so anything goes I guess.  
For mutex server: Tested on CentOS 6.7.  

## Attributes

| Key                          | Type    | Used by            | Description                                                                       | Default |
|:-----------------------------|:--------|:-------------------|:----------------------------------------------------------------------------------|:--------|
| `['mutex_rdlm']['scheme']`   | String  | Clients            | Default for mutex scheme                                                          | http    |
| `['mutex_rdlm']['hostname']` | String  | Clients            | Default for mutex server name                                                     | nil     |
| `['mutex_rdlm']['port']`     | Integer | Server and Clients | Port for mutex server. Used as default by clients                                 | 7305    |
| `['mutex_rdlm']['wait']`     | Integer | Clients            | Default for number of seconds to wait to acquire the lock before raising an error | 5       |
| `['mutex_rdlm']['lifetime']` | Integer | Clients            | Default for how logn the lock hols before expiring by itself                      | 300     |

## Recipes

### mutex\_rdlm::server
Installs and configures the simple RDLM server.  
It uses the `['mutex_rdlm']['port']` attribute to determine the port the daemon will be listening on.  
I'm using an init file tested on CentOS 6.7.  

## Library resources

### Common parameters
Used to locate the mutex server, appear under `additional_config` in method descriptions:

* `mutex_url`: How to reach the mutex server. Defaults to building the url from attributes (if possible)
* `mutex_wait`: Number of seconds to wait to acquire the lock before raising an error. Defaults to `node['mutex_rdlm']['wait']`
* `mutex_lifetime`: Number of seconds before the lock will expire on its own. Defaults to `node['mutex_rdlm']['lifetime']`

### MutexRDLM::with\_mutex
Yields (runs a code block) while locking the resource specified on the mutex.  
Parameters:

* `node`: Calling node's object
* `mutex_resource`: name for mutex
* "additional_config" detailed above

Can be thought of like the [synchronized](https://docs.oracle.com/javase/tutorial/essential/concurrency/locksync.html) keyword in java.  
Example:

```ruby
# Add apple to databag if it has none
MutexRDLM::with_mutex(node,'dbvendingjuice') do
  db=data_bag_item('vending','juice')
  db['kinds']<<'apple' unless db['kinds'].member? 'apple'
  db.save
end
```
This will ensure the databag has only one `apple` item, even if several clients run this recipe at the same time.

### MutexRDLM::assign\_identity

Used to assign a unique identity.  
Parameters:

* `node`: Calling node's object
* `assignment_path`: Path for attribute to store unique value in
* `range`: Pool of possibe values
* `additional_config`: Detailed above

#### Resulting effects
Upon successful completion of the function, this node will be assigned a unique identity in its node object.  
The identity will be stored as a node attribute specified by `assignment_path`, where `[:a,0,'bla']` is used to address the node attribute `node[:a][0]['bla']`.  
The value is selected from `range` and is guranteed to be different from any value currently present on other nodes in the Chef server.  
Selection is done without concurrency, thanks to the mutex.  
The resulting value is saved on both the current `node` object (for use in other parts of the recipe) and in the server's version of the `node` object immediately, to stop other nodes from choosing the same value. This is important to mention because by default, Chef client only updates the server's version of the `node` object if the run is successful. In our case, this attribute is updated during resource compilation.  
There are several ways this method can fail:

* Can't talk to mutex server  
    Fix the server, firewalls etc.
* Can't get mutex lock (other client is busy with mutex).
    * My library might be buggy and not release the mutex for some reason. Create a PR/Issue :)
    * Enumerating all of the nodes takes longer than the mutex time constraints. Allow more `wait` time.
* Range is exhausted
    * Increase the range
    * Delete dead nodes from the Chef server

#### Basic walk-through
Assuming a working and reachable mutex server:

1. Function is called with the following:
    * `assignment_path = [:slasher,:id]`
    * `range = (1..5).to_a`
    * `mutex_url = 'http://mutex:8080/'`
    * `mutex_wait = 5`
    * `mutex_lock = 300`
2. Current value of attribute is checked (`node[:slasher][:id]`). If not-empty, function returns. Assuming empty
3. Mutex is locked for a normalized version of the `assignment_path` (`slasherid`)
4. If mutex can't be locked for some reason, raise error
5. All node objects on Chef server are enumerated for that value. Resulting collection is filtered out from range.
6. Take a single element from range (`first`). If empty, raise error (release mutex before). Assuming got `3`.
7. Load our node object from Chef server, modify the node attribute and save it.
8. Update the current node's attribute (`node.normal[:slasher][:id]=3`)
9. Release mutex
10. Return 3

### MutexRDLM::find\_duplicate\_identity
Parameters:

* `node`: Calling node's object
* `assignment_path`: Path for attribute unique value is stored in
* `only_me`: Only check for conflicts involving my node
* `additional_config`: Detailed above

Used to enforce uniqueness of the identity attribute without modifying anything.  
Is useful in monitoring.  

#### Return value
Empty hash (`{}`) if there are no duplicates.  
If there are duplicates, the hash is composed of a key for the duplicate identity and the value is an array of nodes holding said value, like this:

```ruby
{
  3 => ['node1.backslasher.net', 'node2.backslasher.net']
}
```

## License and Authors
Licensed [GPL v2](http://choosealicense.com/licenses/gpl-2.0/)  
Author:: [Nitzan Raz](https://github.com/BackSlasher) ([backslasher](http://backslasher.net/))
