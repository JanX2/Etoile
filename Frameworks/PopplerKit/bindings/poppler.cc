/*/*
 * Copyright (C) 2004  Stefan Kleine Stegemann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#include <stdio.h>
#include <stdlib.h>
#include "poppler.h"
#include <GlobalParams.h>
#include <fontconfig/fontconfig.h>

static void dump_fonts(FcConfig* fcConfig)
{
   FcFontSet* fonts;
   
   printf("---- DUMPING AVAILABLE FONTS ----\n");

   printf("---- SYSTEM FONTS\n");
   fonts = FcConfigGetFonts(fcConfig, FcSetSystem);
   if (fonts != NULL)
   {
      for (int i = 0; i < fonts->nfont; i++)
      {
         FcPatternPrint(fonts->fonts[i]);
      }
   }
   
   printf("\n---- APPLICATION FONTS\n");
   fonts = FcConfigGetFonts(fcConfig, FcSetApplication);
   if (fonts != NULL)
   {
      for (int i = 0; i < fonts->nfont; i++)
      {
         FcPatternPrint(fonts->fonts[i]);
      }
   }

   printf("---- END OF FONT DUMP ----\n");
   fflush(stdout);
}

static FcConfig* create_fc_config(const unsigned char* fcConfigPath)
{
   FcConfig* config = FcConfigCreate();

   if (!config)
   {
      fprintf(stderr, "failed to create FcConfig\n"); fflush(stderr);
      return NULL;
   }

   if (!FcConfigParseAndLoad(config, (const FcChar8*)fcConfigPath, 1))
   {
      FcConfigDestroy(config);
      fprintf(stderr, "failed to load %s\n", fcConfigPath); fflush(stderr);
      return NULL;
   }
   
   if (!FcConfigBuildFonts(config))
   {
      FcConfigDestroy(config);
      fprintf(stderr, "failed to build fonts\n"); fflush(stderr);
      return NULL;
   }
   
   fprintf(stderr, "fontconfig file %s successfully loaded\n",
   fcConfigPath); fflush(stderr);
   
   return config;
}

int poppler_init(const unsigned char* fcConfigPath,
                 const unsigned char* appFonts[],
                 unsigned nappFonts)
{
   if (!globalParams)
   {
      _poppler_objc_init();
      
      // fontconfig initialization
      if (fcConfigPath)
      {
         fprintf(stderr, "using custom fontconfig configuration %s\n", fcConfigPath);
         fflush(stderr);
         FcConfig* fcConfig = create_fc_config(fcConfigPath);
         if (!FcConfigSetCurrent(fcConfig))
         {
            fprintf(stderr, "failed to set current fontconfig config\n");
            fflush(stderr);
         }
      }
      else
      {
         fprintf(stderr, "using default fontconfig configuration\n");
         fflush(stderr);
         FcInit();
      }
      
      // tell fontconfig about application fonts
      for (int i = 0; i < nappFonts; i++)
      {
         if (FcConfigAppFontAddFile(FcConfigGetCurrent(), appFonts[i]))
         {
            fprintf(stderr, "registered application font %s\n", appFonts[i]);
         }
         else
         {
            fprintf(stderr, "failed to register application font %s\n");
         }
         fflush(stderr);
      }

      globalParams = new GlobalParams(NULL);
      globalParams->setupBaseFontsFc(NULL);
      //dump_fonts(FcConfigGetCurrent());
      fprintf(stderr, "poppler library initialized\n"); fflush(stderr);
   }
   
   return 1;
}

