use std/assert
use ./mod.nu *

assert equal (effectiveness glimmora) (effectiveness-types rock poison)
assert equal (effectiveness water) (effectiveness-types water)
assert equal (effectiveness water ghost) (effectiveness-types water ghost)
assert equal (show "sandy shocks" | get name) sandy-shocks
