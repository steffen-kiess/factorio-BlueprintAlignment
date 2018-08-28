Blueprint Alignment
===================

This mod allows enforcing a certain alignment for blueprints, e.g. it can
enforce that a certain blueprint is always build on a 8x8 grid. When
deploying a blueprint, the mod will check whether the blueprint is properly
aligned and shift it to the nearest aligned position otherwise. Note that
when building without SHIFT, the blueprint will only be built if it can be
built both at the position where you are trying to build it and at the
properly aligned position.

Setting the alignment
---------------------

The alignment can be set using the GUI. The blueprint alignment GUI can be
opened whenever you are editing a blueprint by clicking on the blueprint
icon in the upper bar.

You can set the following properties:

* Alignment X/Y: The alignment of the blueprint. Specifying 8 for both
  X and Y will align the blueprint on a 8x8 grid.
* Center X/Y: The position of the point in the blueprint which will be
  aligned. This is important if the blueprint is rotated. If
  "Store as label" is disabled, a cross will be shown in the blueprint where
  the center is.
* Offset X/Y: This is a global offset which will be aligned to the position
  where the blueprint will be built.
* Store as label: When this checkbox is enabled, the alignment properties
  will be stored in the blueprint label. Otherwise (the default) the
  properties will be stored in a special entity in the blueprint.

Mod settings
------------

There is a per-savegame setting for a global X/Y offset. This offset will be
applied to all blueprints. (This can be useful if you want to share
blueprints across savegames but the savegames have used different starting
points.) The default value for the alignment is 1, which means that the
center of a rail can be aligned to an even number. (If the global offset is
even, the corners of straight rails can be aligned.)

Example
-------

The following blueprint contains a roboport and 5 power poles which will
automatically be aligned properly (the supply areas of the roboports will
touch):

    0eNqdk8FuwjAMhl9l8jlFJaPAettuO03adaAqLW6JliZRE9iqKu++pB2MDRiCW23n//I7tTvIxQZ1w6WFtANeKGkgfevA8EoyEXK21QgpcIs1EJCsDlGjcqVVY8ER4HKFn5COHbkoy3kVocDCNryItBJ4oKduSQCl5Zbj4KEP2kxu6hwbf8E/GAJaGa9UMtztaVE8Sgi0/oMmo8QFb39w9CpcoAy8+DTu/jZ3Z2iT45c+gtBvxhlEco0hOrlgaHpTewF7ijbb05524/co/OjU/lz0LEt1zIyHXv28aNZ4rcXGhJIWrM1Z8Z5tldgEpB+Tfa4SKmdCeGHJhEECPlAfmXfd6rWSu7wLBWxs9htt1v5sX9jr+5SSWc30ATNIazSGVaGlbgF9Mws/xElMknhJFvBSlgZtSMUkXjpwYdr75UgPVpCAYDn6/RkIuLp7/fn9W2+rf4/pfEbpfPwQz6hzX3vdQKU=
