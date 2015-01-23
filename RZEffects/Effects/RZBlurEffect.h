//
//  RZBlurEffect.h
//
//  Created by Rob Visentin on 1/16/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZCompositeEffect.h"

@interface RZBlurEffect : RZCompositeEffect

+ (instancetype)effect;
+ (RZCompositeEffect *)effectWithSigma:(GLint)sigma scale:(GLfloat)scale;

@end
