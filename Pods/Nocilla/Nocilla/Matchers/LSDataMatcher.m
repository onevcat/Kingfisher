//
//  LSDataMatcher.m
//  Nocilla
//
//  Created by Luis Solano Bonet on 09/11/14.
//  Copyright (c) 2014 Luis Solano Bonet. All rights reserved.
//

#import "LSDataMatcher.h"

@interface LSDataMatcher ()

@property (nonatomic, copy) NSData *data;

@end

@implementation LSDataMatcher

- (instancetype)initWithData:(NSData *)data {
    self = [super init];

    if (self) {
        _data = data;
    }
    return self;
}

- (BOOL)matches:(NSString *)string {
    return [self.data isEqualToData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
