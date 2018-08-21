Blueprint Alignment
===================

This mod allows enforcing a certain alignment for some blueprints. The desired
alignment is specified either in the blueprint label or in a special entity in
the blueprint (can be modified in the game). For example the label

    Some blueprint (align = 16)

can be used to enforce an alignment of 16. Using `alignx` and `aligny`
different alignments for x and y direction can be set:

    Some blueprint (alignx = 16, aligny = 8)

Other possible options are:

* `offsetx`, `offsety`: Shift the point to which the blueprint is aligned
* `centerx`, `centery`: Shift the point in the blueprint which is aligned
  (the difference to `offsetx`/`offsety` is important when the blueprint is
   rotated)
