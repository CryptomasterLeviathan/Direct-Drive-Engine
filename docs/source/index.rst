Direct Drive Engine Docs
========================

An open source game engine for the Nintendo Entertainment System (NES). The goal of the project is to create a modular game engine that supports a wide range of game types and takes advantage of a custom mapper.


Building and Running
~~~~~~~~~~~~~~~~~~~~

* Install `NESASM3 <http://www.nespowerpak.com/nesasm/>`_
* Add NESASM3 folder to ``Path``
* Run ``NESASM3 sample.asm``
* Open ``sample.nes`` with an emulator or copy it onto an Everdrive N8


Development Status
~~~~~~~~~~~~~~~~~~

Completed:

* Moving multi-part sprites
* Controller input
* Simulated gravity
* Simulated acceleration
* Simulated friction
* Collisions (floor and ceiling)


In Progress:

* Code cleanup and commenting
* Sphinx documentation
* Collisions (walls)
* Horizontally and vertically mirroring multi-part sprites
* Macros for common tasks


Future Goals:

* Development tools
* Animations (mapper based?)
* Horizontal and vertical scrolling
* Pause and menus
* Unit tests (Lua scripts run with FCEUXD SP)
* Custom mapper


.. toctree::
   :maxdepth: 2
   :hidden:

   engine-core
   engine-modules
   references
