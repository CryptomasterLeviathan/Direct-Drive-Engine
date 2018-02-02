; Engine Variables
  .rsset $0000             ; Start variables at address $0000
Param1            .rs 1
Param2            .rs 1
Param3            .rs 1
TempX             .rs 1
TempY             .rs 1
Controller1Status .rs 1
Controller2Status .rs 1
Timer             .rs 1

; List Attributes for Dynamic Objects
ObjectNum         .rs 1    ; The number of objects
ObjectFlags       .rs 10   ; See: Object Attribute Constants
ObjectSpriteNum   .rs 10   ; Number of sprites that make up object
ObjectSprite      .rs 10   ; First sprite address in the PPU (#$02 higher byte is assumed)
ObjectX           .rs 10   ; X position of object
ObjectY           .rs 10   ; Y position of object
ObjectVSpeed      .rs 10   ; Vertical speed of the object
ObjectHSpeed      .rs 10   ; Horizontal speed of the object
ObjectWidth       .rs 10   ; Width of an object
ObjectHeight      .rs 10   ; Height of an object

; List Attributes for Static Objects (walls and floors)
StaticNum         .rs 1
StaticFlags       .rs 10
StaticX           .rs 10
StaticY           .rs 10
StaticWidth       .rs 10
StaticHeight      .rs 10
