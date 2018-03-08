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


; TODO: Remove the DynObjNum and StatObjNum; Just loop through all object to a max constant and check enable flag on each
DynObjNum         .rs 1    ; The number of dynamic objects
StatObjNum        .rs 1    ; The number of static objects


  .rsset $0010
; List Attributes for Dynamic Objects
DynObjFlags       .rs 16   ; See: Object Attribute Constants
DynObjSpriteNum   .rs 16   ; Number of sprites that make up object
DynObjSprite      .rs 16   ; First sprite address in the PPU (#$02 higher byte is assumed)
DynObjX           .rs 16   ; X position of object
DynObjY           .rs 16   ; Y position of object
DynObjHSpeed      .rs 16   ; Horizontal speed of the object
DynObjVSpeed      .rs 16   ; Vertical speed of the object
DynObjWidth       .rs 16   ; Width of an object
DynObjHeight      .rs 16   ; Height of an object

; List Attributes for Static Objects (walls and floors)
StatObjFlags      .rs 16
StatObjX          .rs 16
StatObjY          .rs 16
StatObjWidth      .rs 16
StatObjHeight     .rs 16
