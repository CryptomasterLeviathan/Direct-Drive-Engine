; Include an engine assembly file and place it at a specific location
  .macro inceng
  .org \2
  .include "\1"
  .endm

; Add Dynamic Object
; Prereq: Put the object index in x register
; Need: flags, number of sprite, starting sprite PPU index, x position, y position, horizontal speed, vertical speed, width, height
; Note: Need to have the sprites already in the PPU
  .macro addDynObj
  LDA \1
  STA DynObjFlags, x
  LDA \2
  STA DynObjSpriteNum, x
  LDA \3
  STA DynObjSprite, x
  LDA \4
  STA DynObjX, x
  LDA \5
  STA DynObjY, x
  LDA \6
  STA DynObjHSpeed, x
  LDA \7
  STA DynObjVSpeed, x
  LDA \8
  STA DynObjWidth, x
  LDA \9
  STA DynObjHeight, x
  .endm

; Add Static Object
; Prereq: Put the object index in x register
; Need: flags, x, y, width, height
; Note: Will need to add information about the background tile(s) in order to enable and disable Static Objects
  .macro addStatObj
  LDA \1
  STA StatObjFlags, x
  LDA \2
  STA StatObjX, x
  LDA \3
  STA StatObjY, x
  LDA \4
  STA StatObjWidth, x
  LDA \5
  STA StatObjHeight, x
  .endm
