/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "ImageTextCell.h"

@interface NumberedImageTextCell : ImageTextCell
{
    int _number;
}

-(void)setNumber: (int) number;

@end

