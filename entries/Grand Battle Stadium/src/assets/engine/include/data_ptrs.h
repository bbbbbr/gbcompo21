#ifndef DATA_PTRS_H
#define DATA_PTRS_H

//------------------------------------------------------------------------------	
// <auto-generated>	
//     This code will be auto generated by GB Studio and is only present here	
//     to supress errors shown during engine development.	
//	
//     Changes to this file may cause incorrect behavior and will be lost if	
//     the project is regenerated.	
// </auto-generated>	
//------------------------------------------------------------------------------
#include "BankData.h"
#define DATA_PTRS_BANK 5
#define FONT_BANK 6
#define FONT_BANK_OFFSET 0
#define FRAME_BANK 6
#define FRAME_BANK_OFFSET 3584
#define CURSOR_BANK 6
#define CURSOR_BANK_OFFSET 3728
#define EMOTES_SPRITE_BANK 6
#define EMOTES_SPRITE_BANK_OFFSET 3744
#define NUM_VARIABLES 500
#define TMP_VAR_1 100
#define TMP_VAR_2 101

extern const BankPtr tileset_bank_ptrs[];
extern const BankPtr background_bank_ptrs[];
extern const BankPtr background_attr_bank_ptrs[];
extern const BankPtr palette_bank_ptrs[];
extern const BankPtr sprite_bank_ptrs[];
extern const BankPtr scene_bank_ptrs[];
extern const BankPtr collision_bank_ptrs[];
extern const BankPtr avatar_bank_ptrs[];
extern const unsigned int bank_data_ptrs[];
extern const unsigned int music_tracks[];
extern const unsigned char music_banks[];
extern unsigned int start_scene_index;
extern int start_scene_x;
extern int start_scene_y;
extern char start_scene_dir_x;
extern char start_scene_dir_y;
extern unsigned int start_player_sprite;
extern unsigned char start_player_move_speed;
extern unsigned char start_player_anim_speed;
extern unsigned char script_variables[114];
extern const unsigned int music_track_101__Data[];
extern WORD plat_min_vel;
extern WORD plat_walk_vel;
extern WORD plat_run_vel;
extern WORD plat_walk_acc;
extern WORD plat_run_acc;
extern WORD plat_dec;
extern WORD plat_jump_vel;
extern WORD plat_grav;
extern WORD plat_hold_grav;
extern WORD plat_max_fall_vel;
extern UBYTE topdown_grid;
extern UBYTE fade_style;
extern UBYTE ui_interactable;
extern UBYTE *engine_fields_addr;

#endif
