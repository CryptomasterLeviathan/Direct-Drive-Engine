; Include an engine assembly file and place it at a specific location
  .macro inceng
  .org \2
  .include "\1"
  .endm

; Add object macro
