  .include "engine-macros.asm"

;;; iNES HEADER
  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring

;;; CONSTANTS
  .include "engine-constants.asm"

;;;; NES RAM
;;; MEMORY ADDRESSES
  .include "engine-addresses.asm"

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

LoadBackgroundSetup:
  LDA $2002         ; TODO: THIS IS CAUSING THE BACKGROUND LOADING TO RESET
  LDA #$20
  STA $2006
  LDA #$00
  STA $2006

  LDY #$00
LoadBackground:
  INY
  LDX backgroundRLE, y    ; Load the run length
  INY                     ; Set Y to the position of the tile location
  LDA backgroundRLE, y    ; Load the tile location
LoadBackgroundRowLoop:
  STA $2007
  DEX
  BNE LoadBackgroundRowLoop
  CPY backgroundRLE       ; Check if we reached the end of the row
  BNE LoadBackground


LoadAttribute:
  LDA $2002
  LDA #$23
  STA $2006
  LDA #$C0
  STA $2006
  LDX #$00
LoadAttributeLoop:
  LDA attribute, x
  STA $2007
  INX
  CPX #$08
  BNE LoadAttributeLoop

  LDA #%10000000   ; enable NMI, sprites from Pattern Table 1
  STA $2000

  LDA #%00011110   ; enable sprites
  STA $2001

;;; INITIALIZE VALUES

  LDA #$00
  STA Timer

  ; Set the number of objects in the list
  LDA #$02
  STA ObjectNum

  ; Set the number of static objects in the list
  LDA #$01
  STA StaticNum

  ; Set sample values in the object, and static object lists
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
  LDA sampleWidth, x
  STA ObjectWidth, x
  LDA sampleHeight, x
  STA ObjectHeight, x
  INX
  CPX ObjectNum
  BNE LoadObjectsLoop

LoadStatic:
  LDX #$00
LoadStaticLoop:
  LDA sampleStaticFlags, x
  STA StaticFlags, x
  LDA sampleStaticX, x
  STA StaticX, x
  LDA sampleStaticY, x
  STA StaticY, x
  LDA sampleStaticWidth, x
  STA StaticWidth, x
  LDA sampleStaticHeight, x
  STA StaticHeight, x
  INX
  CPX StaticNum
  BNE LoadStaticLoop

Forever:
  JMP Forever     ;jump back to Forever, infinite loop

;;;; GAME ENGINE CODE
  .include "engine-core.asm"
  .include "engine-side-scroller.asm"

;;;; SYSTEM INTERRUPTS

NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer

;;; ENGINE CALLS
  JSR UpdateTimer
  LDA Timer
  AND #%00000001
  BEQ EngineSkip
  JSR UpdatePositions
  JSR UpdateSimulation
  JSR UpdateObjectList
  JSR ReadController
  JSR ButtonHandler
EngineSkip:

  ;;This is the PPU clean up section, so rendering the next frame starts properly.
  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001
  LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005

  RTI             ; return from interrupt

;;;; PRG BANK 2

  .bank 1
  .org $E000
palette:
  .db $0F,$16,$26,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$0F
  .db $0F,$11,$38,$17,$31,$02,$38,$3C,$0F,$1C,$15,$14,$31,$02,$38,$3C

backgroundRLE:
  ; 32 tiles wide
  ; 30 tiles high
  .db $48
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $0F,$24, $01,$01, $01,$02, $0F,$24
  .db $0F,$24, $01,$11, $01,$12, $0F,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24
  .db $20,$24

attribute:
  .db %00000000, %00000000, %0000000, %00000000, %00000000, %00000000, %00000000, %00000000


sampleFlags:
  .db %00000011, %00000101

sampleSpriteNum:
  .db $04, $01

sampleSprite:
  .db $00, $10

sampleVSpeed:
  .db $80, $81

sampleHSpeed:
  .db $80, $84

sampleWidth:
  .db $10, $08

sampleHeight:
  .db $10, $08

sampleStaticFlags:
  .db $00

sampleStaticX:
  .db $70

sampleStaticY:
  .db $78

sampleStaticWidth:
  .db $10

sampleStaticHeight:
  .db $10


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
