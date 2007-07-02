/* usplash
 *
 * eft-theme.c - definition of eft theme
 *
 * Copyright © 2006 Dennis Kaarsemaker <dennis@kaarsemaker.net>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
 */

#include <usplash-theme.h>
/* Needed for the custom drawing functions */
#include <usplash_backend.h>

extern struct usplash_pixmap pixmap_etoileboot_800_600, pixmap_etoileboot_1024_768, pixmap_etoileboot_1024_576;
extern struct usplash_font font_helvB10;

void t_init(struct usplash_theme* theme);

struct usplash_theme usplash_theme_1024_768;
struct usplash_theme usplash_theme_1024_576_cropped;

/* Theme definition */
struct usplash_theme usplash_theme = {
	.version = THEME_VERSION, /* ALWAYS set this to THEME_VERSION, 
	                             it's a compatibility check */
	.next = &uspixmap_etoileboot_1024_768,
	.ratio = USPLASH_4_3,

	/* Background and font */
	.pixmap = &pixmap_etoileboot_800_600,

	/* Palette indexes */
	.background             = 0x0,
  	.progressbar_background = 0x7,
  	.progressbar_foreground = 0x156,
	.text_background        = 0x15,
	.text_foreground        = 0x31,
	.text_success           = 0x171,
	.text_failure           = 0x156,

	/* Progress bar position and size in pixels */
  	.progressbar_x      = 292, /* 800/2-216/2 */
  	.progressbar_y      = 371,
  	.progressbar_width  = 216,
  	.progressbar_height = 8,

	/* Text box position and size in pixels */
  	.text_x      = 120,
  	.text_y      = 307,
  	.text_width  = 360,
  	.text_height = 100,

	/* Text details */
  	.line_height  = 15,
  	.line_length  = 32,
  	.status_width = 35,

	/* Functions */
 	.init = t_init,
};

struct usplash_theme usplash_theme_1024_768 = {
	.version = THEME_VERSION,
	.next = &usplash_theme_1024_576_cropped,
	.ratio = USPLASH_4_3,

	/* Background and font */
	.pixmap = &pixmap_etoileboot_1024_768,
	.font   = &font_helvB10,

	/* Palette indexes */
	.background             = 0x0,
  	.progressbar_background = 0x7,
  	.progressbar_foreground = 0x156,
	.text_background        = 0x15,
	.text_foreground        = 0x31,
	.text_success           = 0x171,
	.text_failure           = 0x156,

	/* Progress bar position and size in pixels */
  	.progressbar_x      = 404, /* 1024/2 - 216/2 */
  	.progressbar_y      = 475,
  	.progressbar_width  = 216,
  	.progressbar_height = 8,

	/* Text box position and size in pixels */
  	.text_x      = 322,
  	.text_y      = 525,
  	.text_width  = 380,
  	.text_height = 100,

	/* Text details */
  	.line_height  = 15,
  	.line_length  = 32,
  	.status_width = 35,

	/* Functions */
	.init = t_init,
};

struct usplash_theme usplash_theme_1024_576_cropped = {
	.version = THEME_VERSION,
	.next = NULL,
	.ratio = USPLASH_16_9,

	/* Background and font */
	.pixmap = &pixmap_etoileboot_1024_576,
	.font   = &font_helvB10,

	/* Palette indexes */
	.background             = 0x0,
  	.progressbar_background = 0x7,
  	.progressbar_foreground = 0x156,
	.text_background        = 0x15,
	.text_foreground        = 0x31,
	.text_success           = 0x171,
	.text_failure           = 0x156,

	/* Progress bar position and size in pixels */
  	.progressbar_x      = 276, /* 768/2 - 216/2 */
  	.progressbar_y      = 345,
  	.progressbar_width  = 216,
  	.progressbar_height = 8,

	/* Text box position and size in pixels */
  	.text_x      = 204,
  	.text_y      = 395,
  	.text_width  = 360,
  	.text_height = 100,

	/* Text details */
  	.line_height  = 15,
  	.line_length  = 32,
  	.status_width = 35,

	/* Functions */
	.init = t_init,
};

void t_init(struct usplash_theme *theme) {
    int x, y;
    usplash_getdimensions(&x, &y);
    /*theme->progressbar_x = (x - theme->pixmap->width)/2 + theme->progressbar_x;
    theme->progressbar_y = (y - theme->pixmap->height)/2 + theme->progressbar_y;*/
}

