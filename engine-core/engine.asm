;; ReadController
; A ring counter is used to store controller button state in the address 'Controller1Status'
; Source: https://wiki.nesdev.com/w/index.php/Controller_Reading
ReadController:
  LDA #$01
  ; While the strobe bit is set, buttons will be continuously reloaded.
  STA $4016
  STA Controller1Status
  LSR a        ; now A is 0
  ; By storing 0 into JOYPAD1, the strobe bit is cleared and the reloading stops.
  ; This allows all 8 buttons (newly reloaded) to be read from JOYPAD1.
  STA $4016
ReadControllerLoop:
  LDA $4016
  LSR a	       ; bit0 -> Carry
  ROL Controller1Status  ; Carry -> bit0; bit 7 -> Carry
  BCC ReadControllerLoop
  RTS

;; UpdateTimer
; Runs every frame and increments the Timer value.
; Used to delay or schedule events.
UpdateTimer:
  ; Add 1 to Timer address
  LDA Timer
  CLC
  ADC #$01
  ; Check if there was an overflow
  BCC UpdateTimerSkip
  LDA #$00
UpdateTimerSkip:
  ; Store the new Timer value
  STA Timer
  RTS

;; MoveHorizontal and MoveVertical
; Is used to move multiple sprites (that make up an object) at the same time
; Param1: Number of sprites
; Param2: Starting sprite
; Param3: Speed where the most sig bit is direction: 1 = Add, 0 = Subtract
  MoveVertical:
    LDX Param2        ; Load the first vertical position into X
    JMP MoveSprites   ; Jump to the loop to move each sprite
  MoveHorizontal:
    LDA Param2        ; Load the starting sprite address into A
    CLC
    ADC #$03          ; Add an offset of 3 so that the horizontal values will be modified instead of the vertical values
    TAX               ; Transfer the modified value from A to X
  MoveSprites:
    LDY Param1               ; Load the number of sprites into Y for the main loop
    LDA Param3               ; Load the speed to check the direction bit
    AND #%10000000           ; Check the direction bit
    BEQ MoveSpritesSub       ; Go to the loop which will subtract from the horizontal or vertical value
  MoveSpritesAddLoop:        ; Otherwise continue into this loop and add to the horizontal or verrtical value
    LDA Param3               ; Load the speed
    AND #%01111111           ; Remove the direction bit
    CLC
    ADC $0200, x             ; Add the speed to the horizontal/vertical position with an offset
    STA $0200, x             ; Put the updated position back into the PPU
    TXA                      ; Transfer X to A
    CLC
    ADC #$04                 ; Increment A by 4
    TAX                      ; Transfer A back to X
    DEY
    BNE MoveSpritesAddLoop
    RTS
  MoveSpritesSub:
    LDA #%10000000
    SEC
    SBC Param3
    STA Param3
  MoveSpritesSubLoop:
    LDA $0200, x             ; Load the speed
    SEC
    SBC Param3               ; Add the speed to the horizontal/vertical position with an offset
    STA $0200, x             ; Put the updated position back into the PPU
    TXA                      ; Transfer X to A
    CLC
    ADC #$04                 ; Increment A by 4
    TAX                      ; Transfer A back to X
    DEY
    BNE MoveSpritesSubLoop
    RTS

  ;; UpdatePositions
  ; Updates all object based on their current position and speed
  UpdatePositions:
    LDX #$00
  UpdatePositionsLoop:
    LDA DynObjSpriteNum, x   ; Number of sprites
    STA Param1
    LDA DynObjSprite, x      ; Starting sprite
    STA Param2
    LDA DynObjHSpeed, x      ; Horizontal speed
    STA Param3
    ; TODO: Store and restore the X and Y values in the subroutine?
    STX TempX   ; Stores the X value because subroutines will change the value
    JSR MoveHorizontal
    LDX TempX   ; Restore X value
    LDA DynObjVSpeed, x   ; Vertical speed
    STA Param3
    STX TempX   ; Stores the X value because subroutines will change the value
    JSR MoveVertical
    LDX TempX   ; Restore X value
    INX
    CPX DynObjNum
    BNE UpdatePositionsLoop
    RTS


;; UpdateSimulation
; Loops through each object and applies the appropriate simulations for gravity, friction, etc...
UpdateSimulation:
  LDX #$00
UpdateSimulationLoop:
Gravity:
  LDA DynObjFlags, x            ; Object's flags
  AND #OBJECT_GRAVITY_FLAG      ; Check if the gravity flag is set
  BEQ GravitySkip               ; Skip gravity if the flag is not set
  LDA DynObjSprite, x
  ;CLC
  ;ADC #PPU_VPOSITION           ; Move the offset to the vertical position (not needed because PPU_VPOSITION = 0)
  TAY
  LDA $0200, y
  LDA DynObjVSpeed, x
  CLC
  ADC #$01
  ; TODO: Check max speed
  STA DynObjVSpeed, x
  JMP GravitySkip
GravityStop:
  LDA DynObjFlags, x
  AND #OBJECT_BOUNCE_FLAG
  BEQ GravityNoBounce
  LDA #$78
  STA DynObjVSpeed, x
  JMP GravitySkip
GravityNoBounce:
  ; Check if the object is near the ground
  LDA #$80
  STA DynObjVSpeed, x
GravitySkip:
Friction:
  ; TODO: Check that the left or right buttons are not being pushed (fix the player flickering?)
  LDA DynObjFlags, x            ; Object's flags
  AND #OBJECT_FRICTION_FLAG     ; Check if the friction flag is set
  BEQ FrictionSkip              ; Skip friction if the flag is not set
  LDA DynObjHSpeed, x           ; Load the horizontal speed
  AND #%01111111                ; Check if the speed is zero
  BEQ FrictionSkip
  LDA DynObjHSpeed, x           ; Load the horizontal speed
  AND #%10000000                ; Check the direction of the speed
  BEQ FrictionAdd
  LDA DynObjHSpeed, x           ; Load the horizontal speed
  SEC
  SBC #OBJECT_FRICTION
  STA DynObjHSpeed, x           ; Put the speed back into the correct position
  JMP FrictionSkip
FrictionAdd:
  LDA DynObjHSpeed, x           ; Load the horizontal speed
  CLC
  ADC #OBJECT_FRICTION
  STA DynObjHSpeed, x           ; Put the speed back into the correct position
FrictionSkip:
  JSR StaticCollisions
  INX
  CPX DynObjNum
  BNE UpdateSimulationLoop
  RTS


StaticCollisions:
  ; TODO: Check for enable flag?
  ; Check collision with current dynamic object and all static objects
  ; Static object will be stored sorted based on x position

  ; Check if the object is moving
  LDA DynObjVSpeed, x
  AND #%01111111
  BEQ StaticCollisionsSkip

  ; Skip check if there are no static objects
  LDA StatObjNum
  BEQ StaticCollisionsSkip

  ; Set a flag that the object is not on the ground
  LDA DynObjFlags, x
  AND #%11111011
  STA DynObjFlags, x

  ; Loop through each static object
  LDY #$00
StaticCollisionsMainLoop:
  ; Check if the right side of the dynamic object is greater than the left side of the static object
  LDA DynObjX, x
  CLC
  ADC DynObjWidth, x
  CLC
  CMP StatObjX, y
  BCC StaticCollisionsSkip   ; Branches if the static object's X is larger than the dynamic object's x (e.g. skips the rest of the checks and moves on)
  ; Check if the left side of the dynamic object is less than the right side of the static object
  CLC
  LDA StatObjX, y
  ADC StatObjWidth, y
  CMP DynObjX, x
  BCC StaticCollisionsSkip
  ; Check if the dynamic object is going up or down
  LDA DynObjVSpeed, x
  AND #%10000000
  BEQ StaticCollisionsSub
  ; Check if the bottom of the dynamic object is greater than the top of the static object
  LDA StatObjY, y
  SEC
  SBC DynObjHeight, x
  CMP DynObjY, x
  BCC StaticCollisionsSkip
StaticCollisionsAddLoop:
  ; Check if the bottom of the dynamic object is less than the top of the static object (Remember: Down is positive X)
  LDA DynObjVSpeed, x
  SEC
  SBC #%10000000
  CLC
  ADC DynObjY, x
  CLC
  ADC DynObjHeight, x
  CMP StatObjY, y
  BCC StaticCollisionsSkip
  ; Subtract 1 from the speed and check if it will still collide
  ; Set a flag saying it is on the ground
  LDA DynObjFlags, x
  ORA #%00000100
  STA DynObjFlags, x

  LDA DynObjVSpeed, x
  SEC
  SBC #$01
  STA DynObjVSpeed, x
  JMP StaticCollisionsAddLoop

StaticCollisionsSub:
  ; Check if the top of the dynamic object is greater than the bottom of the static object
  LDA StatObjY, y
  CLC
  ADC StatObjHeight, y
  CMP DynObjY, x
  BCS StaticCollisionsSkip

  JSR StaticCollisionsSubLoop

StaticCollisionsSkip:
  INY
  CPY StatObjNum
  BNE StaticCollisionsMainLoop
  RTS


StaticCollisionsSubLoop:
  LDA #%10000000
  SEC
  SBC DynObjVSpeed, x
  STA Param1
  LDA DynObjY, x
  SEC
  SBC Param1
  STA Param1
  LDA StatObjY, y
  CLC
  ADC StatObjHeight, y
  CMP Param1
  BCC Skip1
  LDA DynObjVSpeed, x
  CLC
  ADC #$01
  STA DynObjVSpeed, x
  JMP StaticCollisionsSubLoop
Skip1:
  RTS


; Helper function to update object positions in the object list
UpdateObjectList:
  LDY #$00                 ; Use Y to index through list
  LDX #$00
UpdateObjectListLoop:
  LDX DynObjSprite, y
  LDA $0200, x             ; Put the updated position back into the PPU
  STA DynObjY, y
  INX
  INX
  INX
  LDA $0200, x
  STA DynObjX, y
  INY
  CPY DynObjNum
  BNE UpdateObjectListLoop
  RTS