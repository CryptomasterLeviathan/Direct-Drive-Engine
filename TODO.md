# TODO

## Current Work
### Display backgrounds with platforms
- How should the level backgrounds be stored?
  - I'm thinking run-length encoding for a starting point (e.g. 32 tiles of sky and 1 tile top left brick 1 tile top right brick)
  - Need to make a function that converts the run-length encoding into the full background and copy it into the PPU

## Future Work
### Collisions
- Store the locations of platforms in a way to limit the number of comparisons needed to check for a collision
  - Sort all static objects by left-right position then bottom-top position?
  - Would something like a binary search tree work?
- Make a modular way to handle different collisions (e.g. set vertical speed to zero when collide with top of block, set horizontal speed to zero when collide with side)

### Stretch Goals
- Make a tool to generate background with a simple GUI that outputs run-length encoded versions of the levels
