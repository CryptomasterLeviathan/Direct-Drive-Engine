.. |br| raw:: html

   <br>


Engine Core
===========

Terminology
~~~~~~~~~~~

* **Dynamic Objects:** An object made using background tiles that cannot move but can me enabled and disabled. Shortened to ``DynObj`` in code.
* **Static Objects:** An object made up of sprites that can move freely. Shortened to ``StatObj`` in code.


Addresses
~~~~~~~~~

Dynamic Object List
^^^^^^^^^^^^^^^^^^^

+---------------------+-----------------------------------------------------------------------------------------+
| Label               | Description                                                                             |
+=====================+=========================================================================================+
| **DynObjFlags**     | The flags contain one byte (8 bits) of extra information about the dynamic object. |br| |
|                     | See :ref:`engine-core:DynObjFlags` section for details.                                 |
+---------------------+-----------------------------------------------------------------------------------------+
| **DynObjSpriteNum** | Blah blah blah...                                                                       |
+---------------------+-----------------------------------------------------------------------------------------+
| **DynObjSprite**    | Blah blah blah...                                                                       |
+---------------------+-----------------------------------------------------------------------------------------+
| **DynObjX**         | Blah blah blah...                                                                       |
+---------------------+-----------------------------------------------------------------------------------------+
| **DynObjY**         | Blah blah blah...                                                                       |
+---------------------+-----------------------------------------------------------------------------------------+
| **DynObjHSpeed**    | Blah blah blah...                                                                       |
+---------------------+-----------------------------------------------------------------------------------------+
| **DynObjVSpeed**    | Blah blah blah...                                                                       |
+---------------------+-----------------------------------------------------------------------------------------+
| **DynObjWidth**     | Blah blah blah...                                                                       |
+---------------------+-----------------------------------------------------------------------------------------+
| **DynObjHeight**    | Blah blah blah...                                                                       |
+---------------------+-----------------------------------------------------------------------------------------+

DynObjFlags
-----------

**EXXXXXXX**

+------------+--------------------------------------------------------------------------------------+
| Letter     | Description                                                                          |
+============+======================================================================================+
| **E**      | 1 if the object is enabled |br|                                                      |
|            | 0 the object is disable, will not be displayed, and will not have physics calculated |
+------------+--------------------------------------------------------------------------------------+
| **X**      | Not defined                                                                          |
+------------+--------------------------------------------------------------------------------------+


Static Object List
^^^^^^^^^^^^^^^^^^

.. note:: Depending on how I eventually optimize collisions, it may require that the static objects are sorted based on x position!

+-------------------+-----------------------------------------------------------------------------------------+
| Label             | Description                                                                             |
+===================+=========================================================================================+
| **StatObjFlags**  | The flags contain one byte (8 bits) of extra information about the static object. |br|  |
|                   | See :ref:`engine-core:StatObjFlags` section for details.                                |
+-------------------+-----------------------------------------------------------------------------------------+
| **StatObjX**      | Blah blah blah...                                                                       |
+-------------------+-----------------------------------------------------------------------------------------+
| **StatObjY**      | Blah blah blah...                                                                       |
+-------------------+-----------------------------------------------------------------------------------------+
| **StatObjWidth**  | Blah blah blah...                                                                       |
+-------------------+-----------------------------------------------------------------------------------------+
| **StatObjHeight** | Blah blah blah...                                                                       |
+-------------------+-----------------------------------------------------------------------------------------+

StatObjFlags
------------

**EXXXXXXX**

+------------+--------------------------------------------------------------------------------------+
| Letter     | Description                                                                          |
+============+======================================================================================+
| **E**      | 1 if the object is enabled |br|                                                      |
|            | 0 the object is disable, will not be displayed, and will not have physics calculated |
+------------+--------------------------------------------------------------------------------------+
| **X**      | Not defined                                                                          |
+------------+--------------------------------------------------------------------------------------+


Engine
~~~~~~

ReadController
^^^^^^^^^^^^^^
.. note:: The code for reading controller input was adapted from `Nesdev <https://wiki.nesdev.com/w/index.php/Controller_Reading>`_. The code seemed perfect, so I decided not to reinvent the wheel.

A ring counter is used to store the button press values into ``Controller1Status`` and ``Controller2Status`` addresses. I will add code to handle a multi-tap, when I get one.

UpdateTimer
^^^^^^^^^^^

Runs every frame and increments the ``Timer`` address value. Used to delay or schedule events.


Macros
~~~~~~

.. warning:: Macros can hide code duplication! It may be more efficient to store values in ``ROM`` and loop through them.

addDynObj
^^^^^^^^^

Adds a dynamic object to the dynamic object list.

**Prerequisites:** Need to have the object index in the ``x`` register and need to have the sprites loaded into the PPU.

**Parameters:**

addStatObj
^^^^^^^^^^

Adds a static object to the static object list.

**Prerequisites:** Need to have the object index in the ``x`` register and need to have the sprites loaded into the PPU.

**Parameters:**
