/*
 *  IKIconPositions.h
 *  
 *
 *  Created by Uli Kusterer on 04.01.05.
 *  Copyright 2005 M. Uli Kusterer. All rights reserved.
 *
 */

#ifndef ICONKIT_IKICONPOSITIONS_H
#define ICONKIT_IKICONPOSITIONS_H 1

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#include <Foundation/Foundation.h>


// -----------------------------------------------------------------------------
//  Constants:
// -----------------------------------------------------------------------------

// Flags from which IKBadgePositions are made up. Don't use these, use IKBadgePosition:
enum IKBadgePositionFlags
{
    IKBadgePositionFlagBottom       = (1 << 0),
    IKBadgePositionFlagLeft         = (1 << 1),
    IKBadgePositionFlagTop          = (1 << 2),
    IKBadgePositionFlagRight        = (1 << 3),
    IKBadgePositionFlagCenter       = (1 << 4),
    IKBadgePositionFlagSemantic     = (1 << 15),    // High bit set means: interpret low 15 bits as icon number.
    IKBadgePositionFlagSemanticMask = 0x7FFF        // Use this to mask out the high bit. (Is this endian-safe?)
};

// Badge position values for badgeRectForPosition:
enum IKBadgePosition
{
    // Semantic positions: (map to absolute positions, but may change depending on OS/theme)
    //  Use e.g. IKBadgePositionStandardSymlink for the theme-provided symlink arrow icon *only*! (they map to full-size on Mac because there the system badges *are* full size)
    //  For other icons, use e.g. IKBadgePositionSymlink instead!!!
    IKBadgePositionStandardLink             = (IKBadgePositionFlagSemantic | 0),
    IKBadgePositionLink                     = (IKBadgePositionFlagSemantic | 1),
    IKBadgePositionStandardReadOnly         = (IKBadgePositionFlagSemantic | 2),
    IKBadgePositionReadOnly                 = (IKBadgePositionFlagSemantic | 3),
    IKBadgePositionStandardDocumentSubIcon  = (IKBadgePositionFlagSemantic | 4),
    IKBadgePositionDocumentSubIcon          = (IKBadgePositionFlagSemantic | 5),
    IKBadgePositionStandardPluginSubIcon    = (IKBadgePositionFlagSemantic | 6),
    IKBadgePositionPluginSubIcon            = (IKBadgePositionFlagSemantic | 7),
    IKBadgePositionStandardLocked           = (IKBadgePositionFlagSemantic | 8),
    IKBadgePositionLocked                   = (IKBadgePositionFlagSemantic | 9),
    IKBadgePositionStandardScript           = (IKBadgePositionFlagSemantic | 10),
    IKBadgePositionScript                   = (IKBadgePositionFlagSemantic | 11),
    IKBadgePositionStandardWriteOnly        = (IKBadgePositionFlagSemantic | 12),
    IKBadgePositionWriteOnly                = (IKBadgePositionFlagSemantic | 13),
        // ... up to 32767 special icon positions :-)
    
    // Absolute positions:
    IKBadgePositionNone             = 0,
    IKBadgePositionBottom           = (IKBadgePositionFlagBottom | IKBadgePositionFlagCenter),
    IKBadgePositionBottomLeft       = (IKBadgePositionFlagBottom | IKBadgePositionFlagLeft),
    IKBadgePositionBottomRight      = (IKBadgePositionFlagBottom | IKBadgePositionFlagRight),
    IKBadgePositionTop              = (IKBadgePositionFlagTop | IKBadgePositionFlagCenter),
    IKBadgePositionTopLeft          = (IKBadgePositionFlagTop | IKBadgePositionFlagLeft),
    IKBadgePositionTopRight         = (IKBadgePositionFlagTop | IKBadgePositionFlagRight),
    IKBadgePositionLeft             = (IKBadgePositionFlagLeft | IKBadgePositionFlagCenter),
    IKBadgePositionRight            = (IKBadgePositionFlagRight | IKBadgePositionFlagCenter),
    IKBadgePositionCenter           = (IKBadgePositionFlagCenter)
};
typedef enum IKBadgePosition IKBadgePosition;

#endif /*ICONKIT_IKICONPOSITIONS_H*/
