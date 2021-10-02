/*
    Copyright 2021 Gearóid Fox

    This file is part of <corrib75>.

    <corrib75> is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    <corrib75> is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with <corrib75>.  If not, see <https://www.gnu.org/licenses/>.
*/

#ifndef __lasers_h_INCLUDE
#define __lasers_h_INCLUDE

#include "misc.h"

extern uint8_t laser_x;
extern uint8_t laser_y;
extern uint8_t laser_end_y;
extern boolean laser_on;

extern void draw_lasers(void);
extern void lasers_recalc(void);
extern void lasers_recalc_box(void);
extern void init_lasers(void);

#endif
