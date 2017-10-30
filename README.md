# Direct Drive Engine

This is an open source game engine for the NES.

## Progress

### Done
- Controller input
- Move objects based on speed
- Simulate gravity
- Simulate friction

### In Progress
- Documentation (using Sphinx)
- Mirror objects (horizontally and vertically)
- Collisions (ensure fast moving objects do not intersect solid objects)

### To Do
- Animations (mapper based)

## Assembling and Running
- Install NESASM3
- Add NESASM3 to `Path`
- Run `NESASM3 engine.asm`
- Open `engine.nes` in an emulator

## Resources
- [Nerdy Nights Tutorial](http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=7155)
  - A great resource for new NES programmers and the source of the boilerplate code used in the engine.
