# mutex_identity cookbook

Uses an external mutex to assign unique identities to Chef clients.  
Also supports managing the mutex server using [RDLM](https://github.com/thefab/restful-distributed-lock-manager)

## Supported Platforms

For clients: Nothing native, so anything goes I guess.  
For mutex server: Tested on CentOS 6.7.  

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Used by</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['mutex_identity']['scheme']</tt></td>
    <td>String</td>
    <td>Clients</td>
    <td>Default for mutex scheme</td>
    <td><tt>http</tt></td>
  </tr>
  <tr>
    <td><tt>['mutex_identity']['hostname']</tt></td>
    <td>String</td>
    <td>Clients</td>
    <td>Default for mutex server name</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['mutex_identity']['port']</tt></td>
    <td>Integer</td>
    <td>Server and Clients</td>
    <td>Port for mutex server. Used as default by clients</td>
    <td><tt>7305</tt></td>
  </tr>
  <tr>
    <td><tt>['mutex_identity']['wait']</tt></td>
    <td>Integer</td>
    </td>Clients</td>
    <td>Default for number of seconds to wait to acquire the lock before raising an error</td>
    <td><tt>5</tt></td>
  </tr>
  <tr>
    <td><tt>['mutex_identity']['lifetime']</tt></td>
    <td>Integer</td>
    <td>Clients</td>
    <td>Default for how long the lock holds before expiring</td>
    <td><tt>300</tt></td>
  </tr>
</table>

## Recipes

### mutex_identity::server
Installs and configures the simple RDLM server.  
It uses the `['mutex_identity']['port']` attribute to determine the port the daemon will be listening on.  
I'm using an init file tested on CentOS 6.7.  

## Library resources

### `MutexIdentity::assign_identity(node,assignment_path,range,*additional_config)`
Used to assign a unique identity.  
Additional (optional) parameters:

* `mutex_url`: How to reach the mutex server. Defaults to building the url from attributes (if possible)
* `mutex_wait`: Number of seconds to wait to acquire the lock before raising an error. Defaults to `node['mutex_identity']['wait']`
* `mutex_lifetime`: Number of seconds before the lock will expire on its own. Defaults to `node['mutex_identity']['lifetime']`

#### Resulting effects
Upon successful completion of the function, this node will be assigned a unique identity in its node object.  
The identity will be stored as a node attribute specified by `assignment_path`, where `[:a,0,'bla']` is used to address the node attribute `node[:a][0]['bla']`.  
The value is selected from `range` and is guranteed to be different from any value currently present on other nodes in the Chef server.  
Selection is done without concurrency, which is enforced by the RDLM mutex.  
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

### `MutexIdentity::find_duplicates(node,assignment_path,only_me=false)`
Used to enforce uniqueness of the identity attribute without modifying anything.  
Is useful in monitoring.  
`only_me` is used to cotrol whether to ensure only the current node is unique, or check all nodes in the Chef server.  
#### Return value
`nil` if there are no duplicates found.  
If there are duplicates, the returned result is a hash, where the key is the duplicate identity and the value is an array of nodes holding said value, like this:
```ruby
{
  3 => ['node1.backslasher.net', 'node2.backslasher.net']
}
```

## License and Authors
Licensed [GPL v2](http://choosealicense.com/licenses/gpl-2.0/)
Author:: [Nitzan Raz](https://github.com/BackSlasher) ([backslasher](http://backslasher.net/))
