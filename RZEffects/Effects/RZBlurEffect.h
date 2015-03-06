//
//  RZBlurEffect.h
//
//  Created by Rob Visentin on 1/16/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZEffect.h"

@interface RZBlurEffect : RZEffect

@property (assign, nonatomic) GLfloat sigma;

+ (instancetype)effectWithSigma:(GLfloat)sigma;

@end
