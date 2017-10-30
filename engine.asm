;;; iNES HEADER

  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring

;;; CONSTANTS

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

; Object Attribute Constants
OBJECT_GRAVITY_FLAG    = 1 << 0
OBJECT_FRICTION_FLAG   = 1 << 1
OBJECT_BOUNCE_FLAG     = 1 << 2

; Engine Constants
OBJECT_GRAVITY    = $03
OBJECT_FRICTION   = $01
OBJECT_BOUNCE     = $08

;;;; NES RAM

;;; MEMORY ADDRESSES

  .rsset $0000             ; Start variables at address $0000
Param1            .rs 1
Param2            .rs 1
Param3            .rs 1
TempX             .rs 1
TempY             .rs 1
Controller1Status .rs 1
Controller2Status .rs 1

ObjectNum         .rs 1    ; The number of objects
ObjectFlags       .rs 10   ; See: Object Attribute Constants
ObjectSpriteNum   .rs 10   ; Number of sprites that make up object
ObjectSprite      .rs 10   ; First sprite address in the PPU (#$02 higher byte is assumed)
ObjectVSpeed      .rs 10   ; Vertical speed of the object
ObjectHSpeed      .rs 10   ; Horizontal speed of the object

;;;; PRG BANK 1

;;; CODE FROM TUTORIAL

  .bank 0
  .org $C000
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0200, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE clrmem

vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2

LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down

LoadSprites:
  LDX #$00              ; start at 0
LoadSpritesLoop:
  LDA sprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$14              ; Compare X to hex $20, decimal 32
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down

  LDA #%10000000   ; enable NMI, sprites from Pattern Table 1
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

;;; INITIALIZE VALUES

  LDA #$02
  STA ObjectNum

LoadObjects:
  LDX #$00
LoadObjectsLoop:
  LDA sampleFlags, x
  STA ObjectFlags, x
  LDA sampleSpriteNum, x
  STA ObjectSpriteNum, x
  LDA sampleSprite, x
  STA ObjectSprite, x
  LDA sampleVSpeed, x
  STA ObjectVSpeed, x
  LDA sampleHSpeed, x
  STA ObjectHSpeed, x
  INX
  CPX ObjectNum
  BNE LoadObjectsLoop

Forever:
  JMP Forever     ;jump back to Forever, infinite loop

;;;; GAME ENGINE CODE

;;; CORE ENGINE

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
  TAX               ; Transter the modified value from A to X

MoveSprites:
  LDY Param1               ; Load the number of sprites into Y for the main loop
  LDA Param3               ; Load the speed to check the direction bit
  AND #%10000000           ; Check the direction bit
  BEQ MoveSpritesSubLoop   ; Go to the loop which will subtract from the horizontal or vertical value
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
  LDA ObjectSprite, x   ; Starting sprite
  STA Param2
  LDA ObjectHSpeed, x   ; Horizontal speed
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
  AND #OBJECT_GRAVITY_FLAG      ; Check if the friction flag is set
  BEQ GravitySkip               ; Skip friction if the flag is not set

  LDA ObjectSprite, x
  ;CLC
  ;ADC #PPU_VPOSITION           ; Move the offset to the vertical position (not neeeded because PPU_VPOSITION = 0)
  TAY
  LDA $0200, y
  CMP #$D0
  BCS GravityStop

  LDA ObjectVSpeed, x           ; Get the current vertical speed
  AND #%01111111                ; Check if the speed is zero
  BEQ GravityZero
  LDA ObjectVSpeed, x           ; Get the current vertical speed
  AND #%10000000                ; Check the direction of the speed
  BEQ GravitySub
  LDA ObjectVSpeed, x
  CLC
  ADC #$01
  STA ObjectVSpeed, x
  JMP GravitySkip
GravitySub:
  LDA ObjectVSpeed, x
  SEC
  SBC #$01
  STA ObjectVSpeed, x
  JMP GravitySkip
GravityZero:
  LDA #%10000001
  STA ObjectVSpeed, x
  JMP GravitySkip
GravityStop:
  LDA ObjectFlags, x
  AND #OBJECT_BOUNCE_FLAG
  BEQ NoBounce
  LDA #$10
  STA ObjectVSpeed, x
  JMP GravitySkip
NoBounce:
  LDA #$00
  STA ObjectVSpeed, x
GravitySkip:
Friction:
  ; TODO: Check that the left or right buttons are not being pushed (fix the player flickering?)
  LDA ObjectFlags, x            ; Object's flags
  AND #OBJECT_FRICTION_FLAG     ; Check if the friction flag is set
  BEQ FrictionSkip              ; Skip friction if the flag is not set
  LDA ObjectHSpeed, x           ; Horizontal speed
  AND #%01111111                ; Check if speed is zero
  BEQ FrictionSkip
  LDA ObjectHSpeed, x           ; Horizontal speed
  ; TODO: Check that the friction is not larger than the current speed
  ; TODO: CHECK FOR UNDERFLOW!
  SEC
  SBC #OBJECT_FRICTION          ; Subtract 1 from the horizontal speed
  STA ObjectHSpeed, x           ; Put the speed back into the correct position
FrictionSkip:
  INX
  CPX ObjectNum
  BNE UpdateSimulationLoop
  RTS

;;; SIDE-SCROLLING ENGINE
SideScroller:

;;; GAME LOGIC

ButtonHandler:
; Sample do something if a button pushed
  lda Controller1Status
  and #CONTROLLER_LEFT
  beq NotPressingLeft
  ; Handle presses.
  LDX #$00
  LDA #$03
  STA ObjectHSpeed, x
NotPressingLeft:
  lda Controller1Status
  and #CONTROLLER_RIGHT
  beq NotPressingRight
  ; Handle presses.
  LDX #$00
  LDA #$83
  STA ObjectHSpeed, x
NotPressingRight:
  lda Controller1Status
  and #CONTROLLER_UP
  beq NotPressingUp
  ; Handle presses.

  LDA ObjectSprite, x
  ;CLC
  ;ADC #PPU_VPOSITION           ; Move the offset to the vertical position (not neeeded because PPU_VPOSITION = 0)
  TAY
  LDA $0200, y
  CMP #$D0
  BCC NotPressingUp

  LDX #$00
  LDA #$09
  STA ObjectVSpeed, x
NotPressingUp:
  lda Controller1Status
  and #CONTROLLER_DOWN
  beq NotPressingDown
  ; Handle presses.
  ;LDX #$00
  ;LDA #$83
  ;STA ObjectVSpeed, x
NotPressingDown:
  RTS

;;;; SYSTEM INTERRUPTS

NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer

;;; ENGINE CALLS
  JSR UpdatePositions
  JSR UpdateSimulation
  JSR ReadController
  JSR ButtonHandler

  RTI             ; return from interrupt

;;;; PRG BANK 2

  .bank 1
  .org $E000
palette:
  .db $0F,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$0F
  .db $0F,$11,$38,$17,$31,$02,$38,$3C,$0F,$1C,$15,$14,$31,$02,$38,$3C

sampleFlags:
  .db %00000011, %00000101

sampleSpriteNum:
  .db $04, $01

sampleSprite:
  .db $00, $10

sampleVSpeed:
  .db $00, $01

sampleHSpeed:
  .db $00, $84

sprites:
     ;vert tile attr horiz
  .db $80, $32, $00, $80   ; sprite 0
  .db $80, $33, $00, $88   ; sprite 1
  .db $88, $34, $00, $80   ; sprite 2
  .db $88, $35, $00, $88   ; sprite 3
  .db $50, $00, $00, $50   ; Star test sprite

  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial

;;;; CHAR BANK

  .bank 2
  .org $0000
  .incbin "sprites.chr"   ;includes 8KB graphics file
