;-------------------------------------------------------------------------------
;
; GBT Player v2.2.1 rulz
;
; SPDX-License-Identifier: MIT
;
; Copyright (c) 2009-2020, Antonio Ni�o D�az <antonio_nd@outlook.com>
;
;-------------------------------------------------------------------------------

	.globl  __current_bank
	
;-------------------------------------------------------------------------------

	.NR10 = 0xFF10
	.NR11 = 0xFF11
	.NR12 = 0xFF12
	.NR13 = 0xFF13
	.NR14 = 0xFF14
	.NR21 = 0xFF16
	.NR22 = 0xFF17
	.NR23 = 0xFF18
	.NR24 = 0xFF19
	.NR30 = 0xFF1A
	.NR31 = 0xFF1B
	.NR32 = 0xFF1C
	.NR33 = 0xFF1D
	.NR34 = 0xFF1E
	.NR41 = 0xFF20
	.NR42 = 0xFF21
	.NR43 = 0xFF22
	.NR44 = 0xFF23
	.NR50 = 0xFF24
	.NR51 = 0xFF25
	.NR52 = 0xFF26

;-------------------------------------------------------------------------------

	.area	_DATA

;-------------------------------------------------------------------------------
.start_gbt_vars:

gbt_playing::
	.ds	1

gbt_song:: ; pointer to the pointer array
	.ds	2
gbt_bank:: ; bank with the data
	.ds 1
gbt_speed:: ; playing speed
	.ds 1

; Up to 12 bytes per step are copied here to be handled in bank 1
gbt_temp_play_data::
	.ds 12

gbt_loop_enabled::
	.ds 1
gbt_ticks_elapsed::
	.ds	1
gbt_current_step::
	.ds	1
gbt_current_pattern::
	.ds	1
gbt_current_step_data_ptr:: ; pointer to next step data
	.ds 2

;gbt_channels_enabled::
;	.ds	1

gbt_pan:: ; Ch 1-4
	.ds	4*1
gbt_vol:: ; Ch 1-4
	.ds	4*1
gbt_instr:: ; Ch 1-4
	.ds	4*1
gbt_freq:: ; Ch 1-3
	.ds	3*2

gbt_mute_ch1::
	.ds 1
gbt_mute_ch2::
	.ds 1
gbt_mute_ch4::
	.ds 1
	
gbt_channel3_loaded_instrument:: ; current loaded instrument ($FF if none)
	.ds	1

; Arpeggio -> Ch 1-3
gbt_arpeggio_freq_index::
	.ds 3*3 ; { base index, base index + x, base index + y } * 3
gbt_arpeggio_enabled::
	.ds 3*1 ; if 0, disabled, if 1, arp, if 2, sweep
gbt_arpeggio_tick::
	.ds	3*1

; Porta Pitch Sweep -> Ch 1-3
gbt_sweep::
	.ds 3*1 ; bit 7 is subtract mode, bit 0-6 is how much.

; Cut note
gbt_cut_note_tick::
	.ds	4*1 ; If tick == gbt_cut_note_tick, stop note.

; Last step of last pattern this is set to 1
gbt_have_to_stop_next_step::
	.ds 1

gbt_update_pattern_pointers::
	.ds 1 ; set to 1 by jump effects

.end_gbt_vars:
	
;-------------------------------------------------------------------------------

	.area	_CODE

;-------------------------------------------------------------------------------

gbt_wave: ; 8 sounds
	.DB	0xA5,0xD7,0xC9,0xE1,0xBC,0x9A,0x76,0x31,0x0C,0xBA,0xDE,0x60,0x1B,0xCA,0x03,0x93 ; random :P
	.DB	0xF0,0xE1,0xD2,0xC3,0xB4,0xA5,0x96,0x87,0x78,0x69,0x5A,0x4B,0x3C,0x2D,0x1E,0x0F
	.DB	0xFD,0xEC,0xDB,0xCA,0xB9,0xA8,0x97,0x86,0x79,0x68,0x57,0x46,0x35,0x24,0x13,0x02 ; little up-downs
	.DB	0xDE,0xFE,0xDC,0xBA,0x9A,0xA9,0x87,0x77,0x88,0x87,0x65,0x56,0x54,0x32,0x10,0x12
	.DB	0xAB,0xCD,0xEF,0xED,0xCB,0xA0,0x12,0x3E,0xDC,0xBA,0xBC,0xDE,0xFE,0xDC,0x32,0x10 ; triangular broken
	.DB	0xFF,0xEE,0xDD,0xCC,0xBB,0xAA,0x99,0x88,0x77,0x66,0x55,0x44,0x33,0x22,0x11,0x00 ; triangular
;	.DB	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; square 50%
;	.DB	0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.DB	0x45,0x67,0x89,0xAB,0xCD,0xEF,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.DB	0x79,0xBC,0xDE,0xEF,0xFF,0xEE,0xDC,0xB9,0x75,0x43,0x21,0x10,0x00,0x11,0x23,0x45 ; sine

;   .DB	0x67,0x89,0xFF,0xFF,0x98,0x76,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
;   .DB	0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	
; gbt_noise: ; Moved to Mod2GBT for better note range & performance
	; 7 bit, can adjust with pitch C D# F# A# C
	;.DB	0x5F,0x4E,0x3E,0x2F,0x2E,0x2C,0x1F,0x0F
	; 15 bit
	;.DB	0x64,0x54,0x44,0x24,0x00
	;.DB	0x67,0x56,0x46

gbt_frequencies:
	.DW	  44,  156,  262,  363,  457,  547,  631,  710,  786,  854,  923,  986
	.DW	1046, 1102, 1155, 1205, 1253, 1297, 1339, 1379, 1417, 1452, 1486, 1517
	.DW	1546, 1575, 1602, 1627, 1650, 1673, 1694, 1714, 1732, 1750, 1767, 1783
	.DW	1798, 1812, 1825, 1837, 1849, 1860, 1871, 1881, 1890, 1899, 1907, 1915
	.DW	1923, 1930, 1936, 1943, 1949, 1954, 1959, 1964, 1969, 1974, 1978, 1982
	.DW	1985, 1988, 1992, 1995, 1998, 2001, 2004, 2006, 2009, 2011, 2013, 2015

;-------------------------------------------------------------------------------
	
gbt_get_pattern_ptr: ; a = pattern number

	; loads a pointer to pattern a into gbt_current_step_data_ptr

	ld	e,a
	ld	d,#0

	ld	a,(gbt_bank)
	ld	(#0x2000),a ; MBC1, MBC3, MBC5 - Set bank

	ld	hl,#gbt_song
	ld	a,(hl+)
	ld	l,(hl)
	ld	h,a

	; hl = pointer to list of pointers
	; de = pattern number

	add	hl,de
	add	hl,de

	; hl = pointer to pattern a pointer

	ld	a,(hl+)
	ld	h,(hl)
	ld	l,a

	; hl = pointer to pattern a data

	ld	a,l
	ld	(gbt_current_step_data_ptr),a
	ld	a,h
	ld	(gbt_current_step_data_ptr+1),a

	ret

;-------------------------------------------------------------------------------

gbt_get_pattern_ptr_banked:: ; a = pattern number

	; loads a pointer to pattern a into gbt_current_step_data_ptr

	ld	c,a
	ld	b,#0

	ld	a,(gbt_bank)
	ld	(#0x2000),a ; MBC1, MBC3, MBC5 - Set bank

	ld	hl,#gbt_song
	ld	a,(hl+)
	ld	l,(hl)
	ld	h,a

	; hl = pointer to list of pointers
	; de = pattern number

	add	hl,bc
	add	hl,bc

	; hl = pointer to pattern a pointer

	ld	a,(hl+)
	ld	b,(hl)
	or	a,b
	jr	nz,dont_loop$
	ld	(gbt_current_pattern), a ; a = 0
dont_loop$:
	;ld	a,#0x01
	;ld	(#0x2000),a ; MBC1, MBC3, MBC5 - Set bank

	ret

;-------------------------------------------------------------------------------
_gbt_play::

	push	bc

	lda	hl,4(sp)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	c,(hl)
	inc hl
	ld	b,(hl)

	; de = data
	; b = speed, c = bank

	ld	hl,#gbt_song
	ld	(hl),d
	inc	hl
	ld	(hl),e

	ld	a,c
	ld	(gbt_bank),a
	ld	a,b
	ld	(gbt_speed),a

	ld	a,#0
	call	gbt_get_pattern_ptr

	xor	a,a
	ld	(gbt_current_step),a
	ld	(gbt_current_pattern),a
	ld	(gbt_ticks_elapsed),a
	ld	(gbt_loop_enabled),a
	ld	(gbt_have_to_stop_next_step),a
	ld	(gbt_update_pattern_pointers),a
	ld	(gbt_mute_ch1),a
	ld	(gbt_mute_ch2),a
	ld	(gbt_mute_ch4),a

	ld	a,#0xFF
	ld	(gbt_channel3_loaded_instrument),a

	;ld	a,#0x0F
	;ld	(gbt_channels_enabled),a

	ld	hl,#gbt_pan
	ld	a,#0x11 ; L and R
	ld	(hl+),a
	sla	a
	ld	(hl+),a
	sla	a
	ld	(hl+),a
	sla	a
	ld	(hl),a

	ld	hl,#gbt_vol
	ld	a,#0xF0 ; 100%
	ld	(hl+),a
	ld	(hl+),a
	ld	a,#0x20 ; 100%
	ld	(hl+),a
	ld	a,#0xF0 ; 100%
	ld	(hl+),a

	ld	a,#0

	ld	hl,#gbt_instr
	ld	(hl+),a
	ld	(hl+),a
	ld	(hl+),a
	ld	(hl+),a

	ld	hl,#gbt_freq
	ld	(hl+),a
	ld	(hl+),a
	ld	(hl+),a
	ld	(hl+),a
	ld	(hl+),a
	ld	(hl+),a

	ld	(gbt_arpeggio_enabled+0),a
	ld	(gbt_arpeggio_enabled+1),a
	ld	(gbt_arpeggio_enabled+2),a

	ld	a,#0xFF
	ld	(gbt_cut_note_tick+0),a
	ld	(gbt_cut_note_tick+1),a
	ld	(gbt_cut_note_tick+2),a
	ld	(gbt_cut_note_tick+3),a

	ld	a,#0x80
	ldh	(#.NR52),a
	ld	a,#0x00
	ldh	(#.NR51),a
	ld	a,#0x00 ; 0%
	ldh	(#.NR50),a

	xor	a,a
	ldh	(#.NR10),a
	ldh	(#.NR11),a
	ldh	(#.NR12),a
	ldh	(#.NR13),a
	ldh	(#.NR14),a
	ldh	(#.NR21),a
	ldh	(#.NR22),a
	ldh	(#.NR23),a
	ldh	(#.NR24),a
	ldh	(#.NR30),a
	ldh	(#.NR31),a
	ldh	(#.NR32),a
	ldh	(#.NR33),a
	ldh	(#.NR34),a
	ldh	(#.NR41),a
	ldh	(#.NR42),a
	ldh	(#.NR43),a
	ldh	(#.NR44),a

	ld	a,#0x77 ; 100%
	ldh	(#.NR50),a

	ld	a,#0x01
	ld	(gbt_playing),a

	; restore bank
	ld	a,(__current_bank)
	ld	(#0x2000),a ; MBC1, MBC3, MBC5 - Set bank 1

	pop	bc
	ret

;-------------------------------------------------------------------------------
_gbt_mute_channel1::
	lda	hl,2(sp)
	ld	a,(hl)
	ld	(gbt_mute_ch1),a
	ret
	
;-------------------------------------------------------------------------------
_gbt_mute_channel2::
	lda	hl,2(sp)
	ld	a,(hl)
	ld	(gbt_mute_ch2),a
	ret	
	
;-------------------------------------------------------------------------------
_gbt_mute_channel4::
	lda	hl,2(sp)
	ld	a,(hl)
	ld	(gbt_mute_ch4),a
	ret	
	
;-------------------------------------------------------------------------------

_gbt_pause::
	lda	hl,2(sp)
	ld	a,(hl)
	ld	(gbt_playing),a
	or	a
	jr	nz,.gbt_pause_unmute
	ldh	(#.NR50),a ; Mute sound: set L & R sound levels to Off
	ret

.gbt_pause_unmute: ; Unmute sound if playback is resumed
	ld	a,#0x77
	ldh	(#.NR50),a ; Restore L & R sound levels to 100%
	ret

;-------------------------------------------------------------------------------

_gbt_loop::
	lda	hl,2(sp)
	ld	a,(hl)
	ld	(gbt_loop_enabled),a
	ret

;-------------------------------------------------------------------------------

_gbt_stop::
	xor	a
	ld	(gbt_playing),a
	ldh	(#.NR50),a
	ldh	(#.NR51),a
	ldh	(#.NR52),a
	ret

;-------------------------------------------------------------------------------

;_gbt_enable_channels::
;	lda	hl,2(sp)
;	ld	a,(hl)
;	ld	(gbt_channels_enabled),a
;	ret

;-------------------------------------------------------------------------------

_gbt_update::

	push	bc

	; gbt_update has some "ret z" and things like that
	; We call it from here to make it easier to mantain both
	; RGBDS and GBDK versions.
	call	gbt_update

	; restore bank
	ld	a,(__current_bank)
	ld	(#0x2000),a ; MBC1, MBC3, MBC5 - Set bank 1
	
	pop	bc

	ret

;-------------------------------------------------------------------------------

gbt_update:

	ld	a,(gbt_playing)
	or	a,a
	ret	z ; If not playing, return

	; Handle tick counter

	ld	hl,#gbt_ticks_elapsed
	ld	a,(gbt_speed) ; a = total ticks
	ld	b,(hl) ; b = ticks elapsed
	inc	b
	ld	(hl),b
	cp	a,b
	jr	z,.dontexit

	; Tick != Speed, update effects and exit
	;ld	a,#0x01
	;ld	(#0x2000),a ; MBC1, MBC3, MBC5 - Set bank 1
	call	gbt_update_effects_bank1 ; Call update function in bank 1

	ret

.dontexit:
	ld	(hl),#0x00 ; reset tick counter

	; Clear tick-based effects
	; ------------------------

	xor	a,a
	ld	hl,#gbt_arpeggio_enabled ; Disable arpeggio
	ld	(hl+),a
	ld	(hl+),a
	ld	(hl),a
	dec	a ; a = 0xFF
	ld	hl,#gbt_cut_note_tick ; Disable cut note
	ld	(hl+),a
	ld	(hl+),a
	ld	(hl+),a
	ld	(hl),a

	; Update effects
	; --------------

	;ld	a,#0x01
	;ld	(#0x2000),a ; MBC1, MBC3, MBC5 - Set bank 1
	call	gbt_update_effects_bank1 ; Call update function in bank 1

	; Check if last step
	; ------------------

	ld	a,(gbt_have_to_stop_next_step)
	or	a,a
	jr	z,.dont_stop

	call	_gbt_stop
	ld	a,#0
	ld	(gbt_have_to_stop_next_step),a
	ret

.dont_stop:

	; Get this step data
	; ------------------

	; Change to bank with song data

	ld	a,(gbt_bank)
	ld	(#0x2000),a ; MBC1, MBC3, MBC5

	; Get step data

	ld	a,(gbt_current_step_data_ptr)
	ld	l,a
	ld	a,(gbt_current_step_data_ptr+1)
	ld	h,a ; hl = pointer to data

	ld	de,#gbt_temp_play_data

	ld	b,#4
.copy_loop:	; copy as bytes as needed for this step

	ld	a,(hl+)
	ld	(de),a
	inc	de
	bit	7,a
	jr	nz,.more_bytes
	bit	6,a
	jr	z,.no_more_bytes_this_channel

	jr	.one_more_byte

.more_bytes:

	ld	a,(hl+)
	ld	(de),a
	inc	de
	bit	7,a
	jr	z,.no_more_bytes_this_channel

.one_more_byte:

	ld	a,(hl+)
	ld	(de),a
	inc	de

.no_more_bytes_this_channel:
	dec	b
	jr	nz,.copy_loop

	ld	a,l
	ld	(gbt_current_step_data_ptr),a
	ld	a,h
	ld	(gbt_current_step_data_ptr+1),a ; save pointer to data

	; Increment step/pattern
	; ----------------------

	; Increment step

	ld	a,(gbt_current_step)
	inc	a
	ld	(gbt_current_step),a
	cp	a,#64
	jr	nz,.dont_increment_pattern

	; Increment pattern

	ld	a,#0
	ld	(gbt_current_step),a ; Step 0

	ld	a,(gbt_current_pattern)
	inc	a
	ld	(gbt_current_pattern),a

	call	gbt_get_pattern_ptr

	ld	a,(gbt_current_step_data_ptr)
	ld	b,a
	ld	a,(gbt_current_step_data_ptr+1)
	or	a,b
	jr	nz,.not_ended ; if pointer is 0, song has ended

	ld	a,(gbt_loop_enabled)
	and	a,a

	jr	z,.loop_disabled

	; If loop is enabled, jump to pattern 0

	ld	a,#0
	ld	(gbt_current_pattern),a

	call	gbt_get_pattern_ptr

	jr	.end_handling_steps_pattern

.loop_disabled:

	; If loop is disabled, stop song
	; Stop it next step, if not this step wont be played

	ld	a,#1
	ld	(gbt_have_to_stop_next_step),a

.not_ended:

.dont_increment_pattern:

.end_handling_steps_pattern:

	;ld	a,#0x01
	;ld	(#0x2000),a ; MBC1, MBC3, MBC5 - Set bank 1
	call	gbt_update_bank1 ; Call update function in bank 1

	; Check if any effect has changed the pattern or step

	ld	a,(gbt_update_pattern_pointers)
	and	a,a
	ret	z
	; if any effect has changed the pattern or step, update

	xor	a,a
	ld	(gbt_update_pattern_pointers),a ; clear update flag

	ld	(gbt_have_to_stop_next_step),a ; clear stop flag

	ld	a,(gbt_current_pattern)
	call	gbt_get_pattern_ptr ; set ptr to start of the pattern

	; Search the step

	; Change to bank with song data

	ld	a,(gbt_bank)
	ld	(#0x2000),a ; MBC1, MBC3, MBC5

	ld	a,(gbt_current_step_data_ptr)
	ld	l,a
	ld	a,(gbt_current_step_data_ptr+1)
	ld	h,a ; hl = pointer to data

	ld	a,(gbt_current_step)
	and	a,a
	ret	z ; if changing to step 0, exit

	sla	a
	sla	a
	ld	b,a ; b = iterations = step * 4 (number of channels)
.next_channel:

	ld	a,(hl+)
	bit	7,a
	jr	nz,.next_channel_more_bytes
	bit	6,a
	jr	z,.next_channel_no_more_bytes_this_channel

	jr	.next_channel_one_more_byte

.next_channel_more_bytes:

	ld	a,(hl+)
	bit	7,a
	jr	z,.next_channel_no_more_bytes_this_channel

.next_channel_one_more_byte:

	ld	a,(hl+)

.next_channel_no_more_bytes_this_channel:
	dec	b
	jr	nz,.next_channel

	ld	a,l
	ld	(gbt_current_step_data_ptr),a
	ld	a,h
	ld	(gbt_current_step_data_ptr+1),a ; save pointer to data

	ret
	
;-------------------------------------------------------------------------------

; end gbt_player.s

;-------------------------------------------------------------------------------

_gbt_get_freq_from_index: ; a = index, bc = returned freq
	ld	hl,#gbt_frequencies
	ld	c,a
	ld	b,#0
	add	hl,bc
	add	hl,bc
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ret

;-------------------------------------------------------------------------------
;---------------------------------- Channel 1 ----------------------------------
;-------------------------------------------------------------------------------

gbt_channel_1_handle:: ; de = info

	ld	a,(de)
	inc	de

	bit	7,a
	jr	nz,ch1_has_frequency$

	; Not frequency

	bit	6,a
	jr	nz,ch1_instr_effects$

	; Set volume or NOP

	bit	5,a
	jr	nz,ch1_just_set_volume$

	; NOP

	ret

ch1_just_set_volume$:

	; Set volume

	and	a,#0x0F
	swap	a
	; Preserve envelope data
	ld	b,a			; save byte
	ld	a,(gbt_vol+0)
	and	a,#0x0F		; mask envelope
	or	a,b

	ld	(gbt_vol+0),a

	jr	refresh_channel1_regs_trig$

ch1_instr_effects$:

	; Set instrument and effect

	ld	b,a ; save byte

	and	a,#0x30
	sla	a
	sla	a
	ld	(gbt_instr+0),a ; Instrument

	ld	a,b ; restore byte

	and	a,#0x0F ; a = effect

	call	gbt_channel_1_set_effect

	and a,a
	;ret	z ; if 0, dont refresh registers, Disabled to set instrument
	jr	refresh_channel1_regs_notrig$

ch1_has_frequency$:

	; Has frequency

	and	a,#0x7F
	ld	(gbt_arpeggio_freq_index+0*3),a
	; This destroys hl and a. Returns freq in bc
	call	_gbt_get_freq_from_index

	ld	a,c
	ld	(gbt_freq+0*2+0),a
	ld	a,b
	ld	(gbt_freq+0*2+1),a ; Get frequency

	ld	a,(de)
	inc	de

	bit	7,a
	jr	nz,ch1_freq_instr_and_effect$

	; Freq + Instr + Volume

	ld	b,a ; save byte

	and	a,#0x30
	sla	a
	sla	a
	ld	(gbt_instr+0),a ; Instrument

	ld	a,b ; restore byte

	and	a,#0x0F ; a = volume

	swap	a
	; Preserve envelope data
	ld	b,a			; save byte
	ld	a,(gbt_vol+0)
	and	a,#0x0F		; mask envelope
	or	a,b

	ld	(gbt_vol+0),a

	jr	refresh_channel1_regs_trig$

ch1_freq_instr_and_effect$:

	; Freq + Instr + Effect

	ld	b,a ; save byte

	and	a,#0x30
	sla	a
	sla	a
	ld	(gbt_instr+0),a ; Instrument

	ld	a,b ; restore byte

	and	a,#0x0F ; a = effect

	call	gbt_channel_1_set_effect

	;jr	refresh_channel1_regs_trig$


	; fall through!

; -----------------

refresh_channel1_regs_trig$:

channel1_refresh_registers_trig:

	ld	a,(gbt_mute_ch1)
	or	a,a
	ret	nz

	xor	a,a
	ld	(#.NR10),a
	ld	a,(gbt_instr+0)
	ld	(#.NR11),a
	ld	a,(gbt_vol+0)
	ld	(#.NR12),a
	ld	a,(gbt_freq+0*2+0)
	ld	(#.NR13),a
	ld	a,(gbt_freq+0*2+1)
	or	a,#0x80 ; start
	ld	(#.NR14),a

	ret

refresh_channel1_regs_notrig$:

channel1_refresh_registers_notrig:

	ld	a,(gbt_mute_ch1)
	or	a,a
	ret	nz

	xor	a,a
	ld	(#.NR10),a
	ld	a,(gbt_instr+0)
	ld	(#.NR11),a
	ld	a,(gbt_freq+0*2+0)
	ld	(#.NR13),a
	ld	a,(gbt_freq+0*2+1)
	ld	(#.NR14),a

	ret

; ------------------

channel1_update_effects: ; returns 1 in a if it is needed to update sound registers

	; Cut note
	; --------

	ld	a,(gbt_cut_note_tick+0)
	ld	hl,#gbt_ticks_elapsed
	cp	a,(hl)
	jp	nz,ch1_dont_cut$

	dec	a ; a = 0xFF
	ld	(gbt_cut_note_tick+0),a ; disable cut note

	ld	a,(gbt_mute_ch1)
	or	a,a
	jp	nz,ch1_dont_cut$
	
	xor	a,a ; vol = 0
	ld	(#.NR12),a
	ld	a,#0x80 ; start
	ld	(#.NR14),a

ch1_dont_cut$:

	; Arpeggio or Sweep
	; --------

	ld	a,(gbt_arpeggio_enabled+0)
	and	a,a
	ret	z ; a is 0, return 0

	; Check if Sweep or Arpeggio (4-5 cycles)
	and a,#1
	jr z,gbt_ch1_sweep_run$

	; If enabled arpeggio, handle it

	ld	a,(gbt_arpeggio_tick+0)
	and	a,a
	jr	nz,ch1_not_tick_0$

	; Tick 0 - Set original frequency

	ld	a,(gbt_arpeggio_freq_index+0*3+0)

	call	_gbt_get_freq_from_index

	ld	a,c
	ld	(gbt_freq+0*2+0),a
	ld	a,b
	ld	(gbt_freq+0*2+1),a ; Set frequency

	ld	a,#1
	ld	(gbt_arpeggio_tick+0),a

	ret ; ret 1

ch1_not_tick_0$:

	cp	a,#1
	jr	nz,ch1_not_tick_1$

	; Tick 1

	ld	a,(gbt_arpeggio_freq_index+0*3+1)

	call	_gbt_get_freq_from_index

	ld	a,c
	ld	(gbt_freq+0*2+0),a
	ld	a,b
	ld	(gbt_freq+0*2+1),a ; Set frequency

	ld	a,#2
	ld	(gbt_arpeggio_tick+0),a

	dec	a
	ret ; ret 1

ch1_not_tick_1$:

	; Tick 2

	ld	a,(gbt_arpeggio_freq_index+0*3+2)

	call	_gbt_get_freq_from_index

	ld	a,c
	ld	(gbt_freq+0*2+0),a
	ld	a,b
	ld	(gbt_freq+0*2+1),a ; Set frequency

	xor	a,a
	ld	(gbt_arpeggio_tick+0),a

	inc	a
	ret ; ret 1

gbt_ch1_sweep_run$:

	; PortA Pitch Sweep
	; -----------
	ld	hl,#(gbt_freq+0*2+0)
	ld	a,(gbt_sweep+0)
	bit 7,a ; bit 7, if nz, sweep up.
	jr  z,gbt_ch1_sweep_up$

	; Sweep down -
	sub	a,#0x80
	ld	b,a
	ld	a,(hl)		; Get frequency small (gbt_freq+0*2+0)
	sub	a,b			; subtract b from a
	ld	(hl+),a		; Set frequency small (gbt_freq+0*2+0)
	ld	a,#1
	jr	c,gbt_ch1_sweep_dec$
	ret				; ret 1, update without trigger
	; Sweep down --
gbt_ch1_sweep_dec$:
	dec	(hl)		; DEC frequency large (gbt_freq+0*2+1) 3cy
	ld	a,(hl)
	inc a			; find if decremented past 0 to exactly 255
	ret	nz			; ret/update unless 0
	ld	(hl-),a		; fix frequency large 0x0
	ld	(hl),a		; fix frequency small 0x0
	ld	(gbt_arpeggio_enabled+0),a	; disable sweep
	ret				; ret 0, no update

	; Sweep up +
gbt_ch1_sweep_up$:
	add	a,(hl)		; add frequency small (gbt_freq+0*2+0)
	ld	(hl+),a		; Set frequency small (gbt_freq+0*2+0)
	jr	c,gbt_ch1_sweep_inc$
	ld	a,#1
	ret				; ret 1, update without trigger
	; Sweep up ++
gbt_ch1_sweep_inc$:
	inc	(hl)		; inc frequency large (gbt_freq+0*2+1) 2cy
	ld	a,(hl-)
	and	a,#0x07		; check if wrapped to 0x08 00001000
	ret	nz			; ret/update unless 0
	ld	(gbt_arpeggio_enabled+0),a	; disable sweep
	
	ld	a,(gbt_mute_ch1)
	or	a,a
	ret	nz
	
	xor a,a
	ld	(#.NR12),a ; vol = 0
	ld	a,#0x80 ; start
	ld	(#.NR14),a
	ret 			; ret 0x80, update without trigger

; -----------------

; returns a = 1 if needed to update registers, 0 if not
gbt_channel_1_set_effect: ; a = effect, de = pointer to data.

	ld	hl,#gbt_ch1_jump_table$
	ld	c,a
	ld	b,#0
	add	hl,bc
	add	hl,bc

	ld	a,(hl+)
	ld	h,(hl)
	ld	l,a

	ld	a,(de) ; load args
	inc	de

	jp	(hl)

gbt_ch1_jump_table$:
	.DW	gbt_ch1_pan$
	.DW	gbt_ch1_arpeggio$
	.DW	gbt_ch1_cut_note$
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1_sweep$
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_jump_pattern
	.DW	gbt_ch1234_jump_position
	.DW	gbt_ch1234_speed
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1_NRx2_VolEnv$

gbt_ch1_pan$:
	and	a,#0x11
	ld	(gbt_pan+0),a
	xor	a,a
	ret ; ret 0 do not update registers, only NR51 at end.

gbt_ch1_arpeggio$:
	ld	b,a ; b = params

	ld	hl,#gbt_arpeggio_freq_index+0*3
	ld	c,(hl) ; c = base index
	inc	hl

	ld	a,b
	swap	a
	and	a,#0x0F
	add	a,c

	ld	(hl+),a ; save first increment

	ld	a,b
	and	a,#0x0F
	add	a,c

	ld	(hl),a ; save second increment

	ld	a,#1
	ld	(gbt_arpeggio_enabled+0),a
	ld	(gbt_arpeggio_tick+0),a

	ret ; ret 1

gbt_ch1_cut_note$:
	ld	(gbt_cut_note_tick+0),a
	or	a,a
	jr nz, gbt_ch1_cut_note_nz$
	
	ld	a,(gbt_mute_ch1)
	or	a,a
	jp	nz,gbt_ch1_cut_note_nz$
	
	xor	a,a  ; vol = 0
	ld	(#.NR12),a
	ld	a,#0x80 ; start
	ld	(#.NR14),a
gbt_ch1_cut_note_nz$:
	xor	a,a ; ret 0
	ret

gbt_ch1_NRx2_VolEnv$:	; Raw data into volume, VVVV APPP, bits 4-7 vol
	ld	(gbt_vol+0),a	; bit 3 true = add, bits 0-2 wait period 
	xor	a,a	; ret 0		; 0xF1 = max volume, sub 1 every 1 tick.
	ret					; 0x0A = min volume, add 1 every 2 ticks.

gbt_ch1_sweep$:
	ld 	(gbt_sweep+0),a
	ld	a,#2
	ld	(gbt_arpeggio_enabled+0),a
	xor	a,a	; ret 0
	ret

;-------------------------------------------------------------------------------
;---------------------------------- Channel 2 ----------------------------------
;-------------------------------------------------------------------------------

gbt_channel_2_handle:: ; de = info

	ld	a,(de)
	inc	de

	bit	7,a
	jr	nz,ch2_has_frequency$

	; Not frequency

	bit	6,a
	jr	nz,ch2_instr_effects$

	; Set volume or NOP

	bit	5,a
	jr	nz,ch2_just_set_volume$

	; NOP

	ret

ch2_just_set_volume$:

	; Set volume

	and	a,#0x0F
	swap	a
	; Preserve envelope data
	ld	b,a			; save byte
	ld	a,(gbt_vol+1)
	and	a,#0x0F		; mask envelope
	or	a,b

	ld	(gbt_vol+1),a

	jr	refresh_channel2_regs_trig$

ch2_instr_effects$:

	; Set instrument and effect

	ld	b,a ; save byte

	and	a,#0x30
	sla	a
	sla	a
	ld	(gbt_instr+1),a ; Instrument

	ld	a,b ; restore byte

	and	a,#0x0F ; a = effect

	call	gbt_channel_2_set_effect

	and a,a
	;ret	z ; if 0, dont refresh registers, Disabled to set instrument
	jr	refresh_channel2_regs_notrig$

ch2_has_frequency$:

	; Has frequency

	and	a,#0x7F
	ld	(gbt_arpeggio_freq_index+1*3),a
	; This destroys hl and a. Returns freq in bc
	call	_gbt_get_freq_from_index

	ld	a,c
	ld	(gbt_freq+1*2+0),a
	ld	a,b
	ld	(gbt_freq+1*2+1),a ; Get frequency

	ld	a,(de)
	inc	de

	bit	7,a
	jr	nz,ch2_freq_instr_and_effect$

	; Freq + Instr + Volume

	ld	b,a ; save byte

	and	a,#0x30
	sla	a
	sla	a
	ld	(gbt_instr+1),a ; Instrument

	ld	a,b ; restore byte

	and	a,#0x0F ; a = volume

	swap	a
	; Preserve envelope data
	ld	b,a			; save byte
	ld	a,(gbt_vol+1)
	and	a,#0x0F		; mask envelope
	or	a,b

	ld	(gbt_vol+1),a

	jr	refresh_channel2_regs_trig$

ch2_freq_instr_and_effect$:

	; Freq + Instr + Effect

	ld	b,a ; save byte

	and	a,#0x30
	sla	a
	sla	a
	ld	(gbt_instr+1),a ; Instrument

	ld	a,b ; restore byte

	and	a,#0x0F ; a = effect

	call	gbt_channel_2_set_effect

	;jr	.refresh_channel2_regs_trig

	; fall through!

; -----------------

refresh_channel2_regs_trig$:

channel2_refresh_registers_trig:

	ld	a,(gbt_mute_ch2)
	or	a,a
	ret	nz

	ld	a,(gbt_instr+1)
	ld	(#.NR21),a
	ld	a,(gbt_vol+1)
	ld	(#.NR22),a
	ld	a,(gbt_freq+1*2+0)
	ld	(#.NR23),a
	ld	a,(gbt_freq+1*2+1)
	or	a,#0x80 ; start
	ld	(#.NR24),a

	ret

refresh_channel2_regs_notrig$:

channel2_refresh_registers_notrig:

	ld	a,(gbt_mute_ch2)
	or	a,a
	ret	nz

	ld	a,(gbt_instr+1)
	ld	(#.NR21),a
	ld	a,(gbt_freq+1*2+0)
	ld	(#.NR23),a
	ld	a,(gbt_freq+1*2+1)
	ld	(#.NR24),a

	ret

; ------------------

channel2_update_effects: ; returns 1 in a if it is needed to update sound regs

	; Cut note
	; --------

	ld	a,(gbt_cut_note_tick+1)
	ld	hl,#gbt_ticks_elapsed
	cp	a,(hl)
	jp	nz,ch2_dont_cut$

	dec	a ; a = 0xFF
	ld	(gbt_cut_note_tick+1),a ; disable cut note

	ld	a,(gbt_mute_ch2)
	or	a,a
	jp	nz,ch2_dont_cut$
	
	xor	a,a ; vol = 0
	ld	(#.NR22),a
	ld	a,#0x80 ; start
	ld	(#.NR24),a

ch2_dont_cut$:

	; Arpeggio or Sweep
	; --------

	ld	a,(gbt_arpeggio_enabled+1)
	and	a,a
	ret	z ; a is 0, return 0

	; Check if Sweep or Arpeggio (5-6 cycles)
	and a,#1
	jr z,gbt_ch2_sweep_run$
	; If enabled arpeggio, handle it

	ld	a,(gbt_arpeggio_tick+1)
	and	a,a
	jr	nz,ch2_not_tick_0$

	; Tick 0 - Set original frequency

	ld	a,(gbt_arpeggio_freq_index+1*3+0)

	call	_gbt_get_freq_from_index

	ld	a,c
	ld	(gbt_freq+1*2+0),a
	ld	a,b
	ld	(gbt_freq+1*2+1),a ; Set frequency

	ld	a,#1
	ld	(gbt_arpeggio_tick+1),a

	ret ; ret 1

ch2_not_tick_0$:

	cp	a,#1
	jr	nz,ch2_not_tick_1$

	; Tick 1

	ld	a,(gbt_arpeggio_freq_index+1*3+1)

	call	_gbt_get_freq_from_index

	ld	a,c
	ld	(gbt_freq+1*2+0),a
	ld	a,b
	ld	(gbt_freq+1*2+1),a ; Set frequency

	ld	a,#2
	ld	(gbt_arpeggio_tick+1),a

	dec	a
	ret ; ret 1

ch2_not_tick_1$:

	; Tick 2

	ld	a,(gbt_arpeggio_freq_index+1*3+2)

	call	_gbt_get_freq_from_index

	ld	a,c
	ld	(gbt_freq+1*2+0),a
	ld	a,b
	ld	(gbt_freq+1*2+1),a ; Set frequency

	xor	a,a
	ld	(gbt_arpeggio_tick+1),a

	inc	a
	ret ; ret 1

gbt_ch2_sweep_run$:

	; PortA Pitch Sweep
	; -----------
	ld	hl,#(gbt_freq+1*2+0)
	ld	a,(gbt_sweep+1)
	bit 7,a ; bit 7, if nz, sweep up.
	jr  z,gbt_ch2_sweep_up$

	; Sweep down -
	sub	a,#0x80
	ld	b,a
	ld	a,(hl)		; Get frequency small (gbt_freq+0*2+0)
	sub	a,b			; subtract b from a
	ld	(hl+),a		; Set frequency small (gbt_freq+0*2+0)
	ld	a,#1
	jr	c,gbt_ch2_sweep_dec$
	ret				; ret 1, update without trigger
	; Sweep down --
gbt_ch2_sweep_dec$:
	dec	(hl)		; DEC frequency large (gbt_freq+0*2+1) 3cy
	ld	a,(hl)
	inc a			; find if decremented past 0 to exactly 255
	ret	nz			; ret/update unless 0
	ld	(hl-),a		; fix frequency large 0x0
	ld	(hl),a		; fix frequency small 0x0
	ld	(gbt_arpeggio_enabled+1),a	; disable sweep
	ret				; ret 0, no update

	; Sweep up +
gbt_ch2_sweep_up$:
	add	a,(hl)		; add frequency small (gbt_freq+0*2+0)
	ld	(hl+),a		; Set frequency small (gbt_freq+0*2+0)
	jr	c,gbt_ch2_sweep_inc$
	ld	a,#1
	ret				; ret 1, update without trigger
	; Sweep up ++
gbt_ch2_sweep_inc$:
	inc	(hl)		; inc frequency large (gbt_freq+0*2+1) 2cy
	ld	a,(hl-)
	and	a,#0x07		; check if wrapped to 0x08 00001000
	ret nz			; ret/update unless 0
	ld	(gbt_arpeggio_enabled+1),a	; disable sweep
	
	ld	a,(gbt_mute_ch2)
	or	a,a
	ret	nz
	
	xor	a,a
	ld	(#.NR22),a ; vol = 0
	ld	a,#0x80 ; start
	ld	(#.NR24),a
	ret 			; ret 0x80, update without trigger

; -----------------

; returns a = 1 if needed to update registers, 0 if not
gbt_channel_2_set_effect: ; a = effect, de = pointer to data

	ld	hl,#gbt_ch2_jump_table$
	ld	c,a
	ld	b,#0
	add	hl,bc
	add	hl,bc

	ld	a,(hl+)
	ld	h,(hl)
	ld	l,a

	ld	a,(de) ; load args
	inc	de

	jp	(hl)

gbt_ch2_jump_table$:
	.DW	gbt_ch2_pan$
	.DW	gbt_ch2_arpeggio$
	.DW	gbt_ch2_cut_note$
	.DW	gbt_ch1234_nop
	.DW	gbt_ch2_sweep$
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_jump_pattern
	.DW	gbt_ch1234_jump_position
	.DW	gbt_ch1234_speed
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch2_NRx2_VolEnv$

gbt_ch2_pan$:
	and	a,#0x22
	ld	(gbt_pan+1),a
	xor	a,a ; ret 0
	ret ; Should not update registers, only NR51 at end.

gbt_ch2_arpeggio$:
	ld	b,a ; b = params

	ld	hl,#gbt_arpeggio_freq_index+1*3
	ld	c,(hl) ; c = base index
	inc	hl

	ld	a,b
	swap	a
	and	a,#0x0F
	add	a,c

	ld	(hl+),a ; save first increment

	ld	a,b
	and	a,#0x0F
	add	a,c

	ld	(hl),a ; save second increment

	ld	a,#1
	ld	(gbt_arpeggio_enabled+1),a
	ld	(gbt_arpeggio_tick+1),a

	ret ; ret 1

gbt_ch2_cut_note$:
	ld	(gbt_cut_note_tick+1),a
	or	a,a
	jr nz, gbt_ch2_cut_note_nz$
	
	ld	a,(gbt_mute_ch2)
	or	a,a
	jp	nz,gbt_ch2_cut_note_nz$
	
	xor	a,a  ; vol = 0
	ld	(#.NR22),a
	ld	a,#0x80 ; start
	ld	(#.NR24),a
gbt_ch2_cut_note_nz$:
	xor	a,a ; ret 0
	ret

gbt_ch2_NRx2_VolEnv$:	; raw volumeEnv, VVVV APPP, bits 7-4 vol
	ld	(gbt_vol+1),a	; bit 3 true = add, bits 2-0 wait period 
	xor	a,a	; ret 0		; 0xF1 = max volume, sub 1 every 1 tick.
	ret					; 0x0A = min volume, add 1 every 2 ticks.

gbt_ch2_sweep$:
	ld 	(gbt_sweep+1),a
	ld	a,#2
	ld	(gbt_arpeggio_enabled+1),a
	xor	a,a	; ret 0
	ret

;-------------------------------------------------------------------------------
;---------------------------------- Channel 3 ----------------------------------
;-------------------------------------------------------------------------------

gbt_channel_3_handle:: ; de = info

	ld	a,(de)
	inc	de

	bit	7,a
	jr	nz,ch3_has_frequency$

	; Not frequency

	bit	6,a
	jr	nz,ch3_effects$

	; Set volume or NOP

	bit	5,a
	jr	nz,ch3_just_set_volume$

	; NOP

	ret

ch3_just_set_volume$:

	; Set volume

	swap	a
	ld	(gbt_vol+2),a

	jr	refresh_channel3_regs_trig$

ch3_effects$:

	; Set effect

	and	a,#0x0F ; a = effect

	call	gbt_channel_3_set_effect
	and	a,a
	ret	z ; if 0, dont refresh registers

	jr	refresh_channel3_regs_notrig$

ch3_has_frequency$:

	; Has frequency

	and	a,#0x7F
	ld	(gbt_arpeggio_freq_index+2*3),a
	; This destroys hl and a. Returns freq in bc
	call	_gbt_get_freq_from_index

	ld	a,c
	ld	(gbt_freq+2*2+0),a
	ld	a,b
	ld	(gbt_freq+2*2+1),a ; Get frequency

	ld	a,(de)
	inc	de

	bit	7,a
	jr	nz,ch3_freq_instr_and_effect$

	; Freq + Instr + Volume

	ld	b,a ; save byte

	and	a,#0x0F
	ld	(gbt_instr+2),a ; Instrument

	ld	a,b ; restore byte

	and	a,#0x30 ; a = volume
	sla	a
	ld	(gbt_vol+2),a

	jr	refresh_channel3_regs_trig$

ch3_freq_instr_and_effect$:

	; Freq + Instr + Effect

	ld	b,a ; save byte

	and	a,#0x0F
	ld	(gbt_instr+2),a ; Instrument

	ld	a,b ; restore byte

	and	a,#0x70
	swap	a	; a = effect (only 0-7 allowed here)

	call	gbt_channel_3_set_effect

	;jr	.refresh_channel3_regs

	; fall through!

; -----------------
refresh_channel3_regs_trig$:

channel3_refresh_registers_trig:

	xor	a,a
	ld	(#.NR30),a ; disable

	ld	a,(gbt_channel3_loaded_instrument)
	ld	b,a
	ld	a,(gbt_instr+2)
	cp	a,b
	call	nz,gbt_channel3_load_instrument ; a = instrument

	ld	a,#0x80
	ld	(#.NR30),a ; enable

	xor	a,a
	ld	(#.NR31),a
	ld	a,(gbt_vol+2)
	ld	(#.NR32),a
	ld	a,(gbt_freq+2*2+0)
	ld	(#.NR33),a
	ld	a,(gbt_freq+2*2+1)
	or	a,#0x80 ; start
	ld	(#.NR34),a

	ret

refresh_channel3_regs_notrig$:
	; Dont Restart Waveform!
channel3_refresh_registers_notrig:

	ld	a,(gbt_freq+2*2+0)
	ld	(#.NR33),a
	ld	a,(gbt_freq+2*2+1)
	ld	(#.NR34),a

	ret
; ------------------

gbt_channel3_load_instrument:

	ld	(gbt_channel3_loaded_instrument),a

	swap	a ; a = a * 16
	ld	c,a
	ld	b,#0
	ld	hl,#gbt_wave
	add	hl,bc

	ld	c,#0x30
	ld	b,#16
ch3_loop$:
	ld	a,(hl+)
	ldh	(c),a
	inc	c
	dec	b
	jr	nz,ch3_loop$

	ret

; ------------------

channel3_update_effects: ; returns 1 in a if it is needed to update sound regs

	; Cut note
	; --------

	ld	a,(gbt_cut_note_tick+2)
	ld	hl,#gbt_ticks_elapsed
	cp	a,(hl)
	jp	nz,ch3_dont_cut$

	dec	a ; a = 0xFF
	ld	(gbt_cut_note_tick+2),a ; disable cut note

	xor	a,a ; vol = 0
	ld	(#.NR30),a ; disable
	ld	(#.NR32),a
	ld	a,#0x80 ; start
	ld	(#.NR34),a

ch3_dont_cut$:

	; Arpeggio or Sweep
	; --------

	ld	a,(gbt_arpeggio_enabled+2)
	and	a,a
	ret	z ; a is 0, return 0

	; Check if Sweep or Arpeggio (5-6 cycles)
	and a,#1
	jp z,gbt_ch3_sweep_run$

	; If enabled arpeggio, handle it

	ld	a,(gbt_arpeggio_tick+2)
	and	a,a
	jr	nz,ch3_not_tick_0$

	; Tick 0 - Set original frequency

	ld	a,(gbt_arpeggio_freq_index+2*3+0)

	call	_gbt_get_freq_from_index

	ld	a,c
	ld	(gbt_freq+2*2+0),a
	ld	a,b
	ld	(gbt_freq+2*2+1),a ; Set frequency

	ld	a,#1
	ld	(gbt_arpeggio_tick+2),a

	ret ; ret 1

ch3_not_tick_0$:

	cp	a,#1
	jr	nz,ch3_not_tick_1$

	; Tick 1

	ld	a,(gbt_arpeggio_freq_index+2*3+1)

	call	_gbt_get_freq_from_index

	ld	a,c
	ld	(gbt_freq+2*2+0),a
	ld	a,b
	ld	(gbt_freq+2*2+1),a ; Set frequency

	ld	a,#2
	ld	(gbt_arpeggio_tick+2),a

	dec	a
	ret ; ret 1

ch3_not_tick_1$:

	; Tick 2

	ld	a,(gbt_arpeggio_freq_index+2*3+2)

	call	_gbt_get_freq_from_index

	ld	a,c
	ld	(gbt_freq+2*2+0),a
	ld	a,b
	ld	(gbt_freq+2*2+1),a ; Set frequency

	xor	a,a
	ld	(gbt_arpeggio_tick+2),a

	inc	a
	ret ; ret 1

gbt_ch3_sweep_run$:

	; PortA Pitch Sweep
	; -----------
	ld	hl,#(gbt_freq+2*2+0)
	ld	a,(gbt_sweep+2)
	bit 7,a ; bit 7, if nz, sweep up.
	jr  z,gbt_ch3_sweep_up$

	; Sweep down -
	sub	a,#0x80
	ld	b,a
	ld	a,(hl)		; Get frequency small (gbt_freq+0*2+0)
	sub	a,b			; subtract b from a
	ld	(hl+),a		; Set frequency small (gbt_freq+0*2+0)
	ld	a,#1
	jr	c,gbt_ch3_sweep_dec$
	ret				; ret 1, update without trigger
	; Sweep down --
gbt_ch3_sweep_dec$:
	dec	(hl)		; DEC frequency large (gbt_freq+0*2+1) 3cy
	ld	a,(hl)
	inc a			; find if decremented past 0 to exactly 255
	ret	nz			; ret/update unless 0
	ld	(hl-),a		; fix frequency large 0x0
	ld	(hl),a		; fix frequency small 0x0
	ld	(gbt_arpeggio_enabled+2),a	; disable sweep
	ret				; ret 0, no update

	; Sweep up +
gbt_ch3_sweep_up$:
	add	a,(hl)		; add frequency small (gbt_freq+0*2+0)
	ld	(hl+),a		; Set frequency small (gbt_freq+0*2+0)
	jr	c,gbt_ch3_sweep_inc$
	ld	a,#1
	ret				; ret 1, update without trigger
	; Sweep up ++
gbt_ch3_sweep_inc$:
	inc	(hl)		; inc frequency large (gbt_freq+0*2+1) 2cy
	ld	a,(hl-)
	and	a,#0x07		; check if wrapped to 0x08 00001000
	ret	nz			; ret/update unless 0
	ld	(gbt_arpeggio_enabled+2),a	; disable sweep
	ld	(#.NR32),a ; vol = 0
	ld	a,#0x80 ; start
	ld	(#.NR34),a
	ret 			; ret 1, update without trigger

; -----------------

; returns a = 1 if needed to update registers, 0 if not
gbt_channel_3_set_effect: ; a = effect, de = pointer to data

	ld	hl,#gbt_ch3_jump_table$
	ld	c,a
	ld	b,#0
	add	hl,bc
	add	hl,bc

	ld	a,(hl+)
	ld	h,(hl)
	ld	l,a

	ld	a,(de) ; load args
	inc	de

	jp	(hl)

gbt_ch3_jump_table$:
	.DW	gbt_ch3_pan$
	.DW	gbt_ch3_arpeggio$
	.DW	gbt_ch3_cut_note$
	.DW	gbt_ch1234_nop
	.DW	gbt_ch3_sweep$
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_jump_pattern
	.DW	gbt_ch1234_jump_position
	.DW	gbt_ch1234_speed
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop

gbt_ch3_pan$:
	and	a,#0x44
	ld	(gbt_pan+2),a
	xor	a,a ; ret 0
	ret ; do not update registers, only NR51 at end.

gbt_ch3_arpeggio$:
	ld	b,a ; b = params

	ld	hl,#gbt_arpeggio_freq_index+2*3
	ld	c,(hl) ; c = base index
	inc	hl

	ld	a,b
	swap	a
	and	a,#0x0F
	add	a,c

	ld	(hl+),a ; save first increment

	ld	a,b
	and	a,#0x0F
	add	a,c

	ld	(hl),a ; save second increment

	ld	a,#1
	ld	(gbt_arpeggio_enabled+2),a
	ld	(gbt_arpeggio_tick+2),a

	ret ; ret 1

gbt_ch3_cut_note$:
	ld	(gbt_cut_note_tick+2),a
	or	a,a
	jr nz, gbt_ch3_cut_note_nz$
	xor	a,a ; vol = 0
	ld	(#.NR30),a ; disable
	ld	(#.NR32),a
	ld	a,#0x80 ; start
	ld	(#.NR34),a
gbt_ch3_cut_note_nz$:
	xor	a,a ; ret 0
	ret

gbt_ch3_sweep$:
	ld 	(gbt_sweep+2),a
	ld	a,#2
	ld	(gbt_arpeggio_enabled+2),a
	xor	a,a	; ret 0
	ret

;-------------------------------------------------------------------------------
;---------------------------------- Channel 4 ----------------------------------
;-------------------------------------------------------------------------------

gbt_channel_4_handle:: ; de = info

	ld	a,(de)
	inc	de

	bit	7,a
	jr	nz,ch4_has_instrument$

	; Not instrument

	bit	6,a
	jr	nz,ch4_effects$

	; Set volume or NOP

	bit	5,a
	jr	nz,ch4_just_set_volume$

	; NOP

	ret

ch4_just_set_volume$:

	; Set volume

	and	a,#0x0F
	swap	a
	; Preserve envelope data
	ld	b,a			; save byte
	ld	a,(gbt_vol+3)
	and	a,#0x0F		; mask envelope
	or	a,b

	ld	(gbt_vol+3),a

	jr	refresh_channel4_regs$

ch4_effects$:

	; Set effect

	and	a,#0x0F ; a = effect

	call	gbt_channel_4_set_effect
	and	a,a
	ret	z ; if 0, dont refresh registers

	jr	refresh_channel4_regs$

ch4_has_instrument$:

	; Has instrument raw frequency data

	and	a,#0x7F ; mask out bit 7
	ld	b,a

	ld	a,(de)	; load next byte
	inc	de
	ld	c,a
	rla
	and a,#0x80	; Mask only bit 7
	or	a,b		; Append noise bit
	ld	(gbt_instr+3),a
	ld	a,c		; restore byte2
	bit	7,a
	jr	nz,ch4_instr_and_effect$

	; Instr + Volume

	and	a,#0x0F ; a = volume

	swap	a
	; Preserve envelope data
	ld	b,a			; save byte
	ld	a,(gbt_vol+3)
	and	a,#0x0F		; mask envelope
	or	a,b

	ld	(gbt_vol+3),a

	jr	refresh_channel4_regs$

ch4_instr_and_effect$:

	; Instr + Effect

	and	a,#0x0F ; a = effect

	call	gbt_channel_4_set_effect

	;jr	ch4_refresh_channel4_regs$

refresh_channel4_regs$:

	; fall through!

; -----------------

channel4_refresh_registers:

	ld	a,(gbt_mute_ch4)
	or	a,a
	ret	nz

	xor	a,a
	ld	(#.NR41),a
	ld	a,(gbt_vol+3)
	ld	(#.NR42),a
	ld	a,(gbt_instr+3)
	ld	(#.NR43),a
	ld	a,#0x80 ; start
	ld	(#.NR44),a

	ret

; ------------------

channel4_update_effects: ; returns 1 in a if it is needed to update sound regs

	; Cut note
	; --------

	ld	a,(gbt_cut_note_tick+3)
	ld	hl,#gbt_ticks_elapsed
	cp	a,(hl)
	jp	nz,ch4_dont_cut$

	dec	a ; a = 0xFF
	ld	(gbt_cut_note_tick+3),a ; disable cut note

	ld	a,(gbt_mute_ch4)
	or	a,a
	jp	nz,ch4_dont_cut$
	
	xor	a,a ; vol = 0
	ld	(#.NR42),a
	ld	a,#0x80 ; start
	ld	(#.NR44),a

ch4_dont_cut$:

	xor	a,a
	ret ; a is 0, return

; -----------------

; returns a = 1 if needed to update registers, 0 if not
gbt_channel_4_set_effect: ; a = effect, de = pointer to data

	ld	hl,#gbt_ch4_jump_table$
	ld	c,a
	ld	b,#0
	add	hl,bc
	add	hl,bc

	ld	a,(hl+)
	ld	h,(hl)
	ld	l,a

	ld	a,(de) ; load args
	inc	de

	jp	(hl)

gbt_ch4_jump_table$:
	.DW	gbt_ch4_pan$
	.DW	gbt_ch1234_nop ; gbt_ch4_arpeggio
	.DW	gbt_ch4_cut_note$
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_jump_pattern
	.DW	gbt_ch1234_jump_position
	.DW	gbt_ch1234_speed
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch1234_nop
	.DW	gbt_ch4_NRx2_VolEnv$

gbt_ch4_pan$:
	and	a,#0x88
	ld	(gbt_pan+3),a
	xor	a,a ; ret 0
	ret ; do not update registers, only NR51 at end.

gbt_ch4_cut_note$:
	ld	(gbt_cut_note_tick+3),a
	or	a,a
	jr nz, gbt_ch4_cut_note_nz$
	
	ld	a,(gbt_mute_ch4)
	or	a,a
	jp	nz,gbt_ch4_cut_note_nz$
	
	xor	a,a  ; vol = 0
	ld	(#.NR42),a
	ld	a,#0x80 ; start
	ld	(#.NR44),a
gbt_ch4_cut_note_nz$:
	xor	a,a ; ret 0
	ret

gbt_ch4_NRx2_VolEnv$:	; Raw data into volume, VVVV APPP, bits 4-7 vol
	ld	(gbt_vol+3),a	; bit 3 true = add, bits 0-2 wait period 
	xor	a,a	; ret 0		; 0xF1 = max volume, sub 1 every 1 tick.
	ret					; 0x0A = min volume, add 1 every 2 ticks.

;-------------------------------------------------------------------------------

; Common effects go here:

gbt_ch1234_nop:
	xor	a,a ;ret 0
	ret

gbt_ch1234_jump_pattern:
	ld	(gbt_current_pattern),a
	xor	a,a
	ld	(gbt_current_step),a
	ld	(gbt_have_to_stop_next_step),a ; clear stop flag
	ld	a,#1
	ld	(gbt_update_pattern_pointers),a
	xor	a,a ;ret 0
	ret

gbt_ch1234_jump_position:
	ld	(gbt_current_step),a
	ld	hl,#gbt_current_pattern
	inc	(hl)

	; Check to see if jump puts us past end of song
	ld	a,(hl)
	call	gbt_get_pattern_ptr_banked
	ld	a,#1 ; tell gbt_player.s to do this next cycle
	ld	(gbt_update_pattern_pointers),a
	xor	a,a ;ret 0
	ret

gbt_ch1234_speed:
	ld	(gbt_speed),a
	xor	a,a
	ld	(gbt_ticks_elapsed),a
	ret ;ret 0

;-------------------------------------------------------------------------------

gbt_update_bank1::

	ld	de,#gbt_temp_play_data

	; each function will return in de the pointer to next byte

	call	gbt_channel_1_handle

	call	gbt_channel_2_handle

	call	gbt_channel_3_handle

	call	gbt_channel_4_handle

	; end of channel handling

	ld	hl,#gbt_pan
	ld	a,(hl+)
	or	a,(hl)
	inc	hl
	or	a,(hl)
	inc hl
	or	a,(hl)
	ld	(#.NR51),a ; handle panning...

	ret

;-------------------------------------------------------------------------------

gbt_update_effects_bank1::

	call	channel1_update_effects
	and	a,a
	call	nz,channel1_refresh_registers_notrig

	call	channel2_update_effects
	and	a,a
	call	nz,channel2_refresh_registers_notrig

	call	channel3_update_effects
	and	a,a
	call	nz,channel3_refresh_registers_notrig

	call	channel4_update_effects
	and	a,a
	call	nz,channel4_refresh_registers

	ret

;-------------------------------------------------------------------------------