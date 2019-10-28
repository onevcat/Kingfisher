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

- (BOOL)matchesData:(NSData *)data {
    return [self.data isEqualToData:data];
}


#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[LSDataMatcher class]]) {
        return NO;
    }

    return [self.data isEqual:((LSDataMatcher *)object).data];
}

- (NSUInteger)hash {
    return self.data.hash;
}

@end
