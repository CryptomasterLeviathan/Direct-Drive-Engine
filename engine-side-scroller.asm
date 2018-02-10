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
  LDA ObjectHSpeed, x
  SEC
  SBC #$02
  STA ObjectHSpeed, x
NotPressingLeft:
  lda Controller1Status
  and #CONTROLLER_RIGHT
  beq NotPressingRight
  ; Handle presses.
  LDX #$00
  LDA ObjectHSpeed, x
  CLC
  ADC #$02
  STA ObjectHSpeed, x
NotPressingRight:
  lda Controller1Status
  and #CONTROLLER_A
  beq NotPressingA
  ; Handle presses.

  LDA ObjectSprite, x
  ;CLC
  ;ADC #PPU_VPOSITION           ; Move the offset to the vertical position (not neeeded because PPU_VPOSITION = 0)
  ;TAY
  ;LDA $0200, y
  ;CMP #$D0
  ;BCC NotPressingA

  LDX #$00
  LDA ObjectFlags, x
  AND #%00000100
  BEQ NotPressingA
  LDA #$77
  STA ObjectVSpeed, x
NotPressingA:
  lda Controller1Status
  and #CONTROLLER_DOWN
  beq NotPressingDown
  ; Handle presses.
  ;LDX #$00
  ;LDA #$83
  ;STA ObjectVSpeed, x
NotPressingDown:
  RTS
