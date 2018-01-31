;; ReadController
; A ring counter is used to store controller 1 button state in the address 'Controller1Status'
; Source: https://wiki.nesdev.com/w/index.php/Controller_Reading
ReadController:
  LDA #$01
  ; While the strobe bit is set, buttons will be continuously reloaded.
  ; This means that reading from JOYPAD1 will only return the state of the
  ; first button: button A.
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
  LDA Timer
  CMP #$FF
  BNE UpdateTimerInc
  LDA $00
  STA Timer
  RTS
UpdateTimerInc:
  CLC
  ADC #$01
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
  LDA ObjectSpriteNum, x   ; Number of sprites
  STA Param1
  LDA ObjectSprite, x      ; Starting sprite
  STA Param2
  LDA ObjectHSpeed, x      ; Horizontal speed
  STA Param3
  ; TODO: Store and restore the X and Y values in the subroutine?
  STX TempX   ; Stores the X value because subroutines will change the value
  JSR MoveHorizontal
  LDX TempX   ; Restore X value
  LDA ObjectVSpeed, x   ; Vertical speed
  STA Param3
  STX TempX   ; Stores the X value because subroutines will change the value
  JSR MoveVertical
  LDX TempX   ; Restore X value
  INX
  CPX ObjectNum
  BNE UpdatePositionsLoop
  RTS

;; UpdateSimulation
; Loops through each object and applies the appropriate simulations for gravity, friction, etc...
UpdateSimulation:
  LDX #$00
UpdateSimulationLoop:
Gravity:
  LDA ObjectFlags, x            ; Object's flags
  AND #OBJECT_GRAVITY_FLAG      ; Check if the gravity flag is set
  BEQ GravitySkip               ; Skip gravity if the flag is not set
  LDA ObjectSprite, x
  ;CLC
  ;ADC #PPU_VPOSITION           ; Move the offset to the vertical position (not needed because PPU_VPOSITION = 0)
  TAY
  LDA $0200, y
  CMP #$D0
  BCS GravityStop
  LDA ObjectVSpeed, x
  CLC
  ADC #$01
  ; TODO: Check max speed
  STA ObjectVSpeed, x
  JMP GravitySkip
GravityStop:
  LDA ObjectFlags, x
  AND #OBJECT_BOUNCE_FLAG
  BEQ GravityNoBounce
  LDA #$78
  STA ObjectVSpeed, x
  JMP GravitySkip
GravityNoBounce:
  ; Check if the object is near the ground
  LDA #$80
  STA ObjectVSpeed, x
GravitySkip:
Friction:
  ; TODO: Check that the left or right buttons are not being pushed (fix the player flickering?)
  LDA ObjectFlags, x            ; Object's flags
  AND #OBJECT_FRICTION_FLAG     ; Check if the friction flag is set
  BEQ FrictionSkip              ; Skip friction if the flag is not set
  LDA ObjectHSpeed, x           ; Load the horizontal speed
  AND #%01111111                ; Check if the speed is zero
  BEQ FrictionSkip
  LDA ObjectHSpeed, x           ; Load the horizontal speed
  AND #%10000000                ; Check the direction of the speed
  BEQ FrictionAdd
  LDA ObjectHSpeed, x           ; Load the horizontal speed
  SEC
  SBC #OBJECT_FRICTION
  STA ObjectHSpeed, x           ; Put the speed back into the correct position
  JMP FrictionSkip
FrictionAdd:
  LDA ObjectHSpeed, x           ; Load the horizontal speed
  CLC
  ADC #OBJECT_FRICTION
  STA ObjectHSpeed, x           ; Put the speed back into the correct position
FrictionSkip:
  INX
  CPX ObjectNum
  BNE UpdateSimulationLoop
  RTS
