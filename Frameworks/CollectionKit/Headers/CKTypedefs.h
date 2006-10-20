/*
    CKTypedefs.h
    Copyright (C) <2006> Yen-Ju Chen <gmail>
    Copyright (C) <2005> Bjoern Giesler <bjoern@giesler.de>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301      USA
*/

#ifndef _CollectionKit_Typedefs_
#define _CollectionKit_Typedefs_

#define CKMultiValueMask        0x100

typedef enum {
  CKErrorInProperty           = 0x0,
  CKStringProperty            = 0x1,
  CKIntegerProperty           = 0x2,
  CKRealProperty              = 0x3, // NOT SUPPORTED!
  CKDateProperty              = 0x4,
  CKArrayProperty             = 0x5,
  CKDictionaryProperty        = 0x6,
  CKDataProperty              = 0x7,
  CKMultiStringProperty       = CKMultiValueMask | CKStringProperty,
  CKMultiIntegerProperty      = CKMultiValueMask | CKIntegerProperty,
  CKMultiRealProperty         = CKMultiValueMask | CKRealProperty,
  CKMultiDateProperty         = CKMultiValueMask | CKDateProperty,
  CKMultiArrayProperty        = CKMultiValueMask | CKArrayProperty,
  CKMultiDictionaryProperty   = CKMultiValueMask | CKDictionaryProperty,
  CKMultiDataProperty         = CKMultiValueMask | CKDataProperty
} CKPropertyType;

// ================================================================
//      Search APIs
// ================================================================

typedef enum {
  CKEqual,
  CKNotEqual,
  CKLessThan,
  CKLessThanOrEqual,
  CKGreaterThan,
  CKGreaterThanOrEqual,
  CKEqualCaseInsensitive,
  CKContainsSubString,
  CKContainsSubStringCaseInsensitive,
  CKPrefixMatch,
  CKPrefixMatchCaseInsensitive
} CKSearchComparison;

typedef enum {
  CKSearchAnd,
  CKSearchOr
} CKSearchConjunction;

#endif /* _CollectionKit_Typedefs_ */
