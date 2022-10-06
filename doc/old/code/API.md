# Settings
`local SwSettings = require "Switcheroo.Settings"`

## `get(setting: string): any`
* `setting`: `string` - The setting to retrieve.

Returns a setting node using PowerSettings's `get`. Automatically adds the `mod.Switcheroo.` prefix, so `get("replacement.advanced")` is equivalent to `PowerSettings.get("mod.Switcheroo.replacement.advanced")`.

# Other modules
These modules exist but return empty tables:

* `Switcheroo.event.EntitySchema`
* `Switcheroo.event.LevelLoad`
* `Switcheroo.Registrar`
* `Switcheroo.Switcheroo`