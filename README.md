# mutex-identity-cookbook

Uses an external mutex to assign unique identities to Chef clients

## Supported Platforms

TODO: List your supported platforms.

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['mutex-identity']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

## Usage

### mutex-identity::default

Include `mutex-identity` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[mutex-identity::default]"
  ]
}
```

## License and Authors

Author:: YOUR_NAME (<YOUR_EMAIL>)
