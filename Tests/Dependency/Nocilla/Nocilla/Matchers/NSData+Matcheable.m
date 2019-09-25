//
//  NSData+Matcheable.m
//  Nocilla
//
//  Created by Luis Solano Bonet on 09/11/14.
//  Copyright (c) 2014 Luis Solano Bonet. All rights reserved.
//

#import "NSData+Matcheable.h"
#import "LSDataMatcher.h"

@implementation NSData (Matcheable)

- (LSMatcher *)matcher {
    return [[LSDataMatcher alloc] initWithData:self];
}

@end
