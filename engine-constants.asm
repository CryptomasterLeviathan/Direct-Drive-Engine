; Controller Constants
CONTROLLER_A        = 1 << 7
CONTROLLER_B        = 1 << 6
CONTROLLER_SELECT   = 1 << 5
CONTROLLER_START    = 1 << 4
CONTROLLER_UP       = 1 << 3
CONTROLLER_DOWN     = 1 << 2
CONTROLLER_LEFT     = 1 << 1
CONTROLLER_RIGHT    = 1 << 0

; PPU Constants
PPU_VPOSITION    = $00
PPU_TILE         = $01
PPU_ATTRIBUTES   = $02
PPU_HPOSITION    = $03

PPU_ATTR_HFLIP        = 1 << 6
PPU_ATTR_VFLIP        = 1 << 7

; Object Attribute Constants
OBJECT_GRAVITY_FLAG    = 1 << 0
OBJECT_FRICTION_FLAG   = 1 << 1
OBJECT_BOUNCE_FLAG     = 1 << 2

; Engine Constants
OBJECT_GRAVITY    = $03
OBJECT_FRICTION   = $01
OBJECT_BOUNCE     = $08
