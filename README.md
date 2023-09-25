# maskset_shrinker

Shrinks a Data Masker Masking Set file by removing redundant objects from the controller.

Currently it only removes tables, but a future iteration could also remove indexes, FKs, and potentially triggers.

To execute, simply update the parameters at the top of the .ps1 script, and run it.

An example source Mask Set has been provided for convenience.