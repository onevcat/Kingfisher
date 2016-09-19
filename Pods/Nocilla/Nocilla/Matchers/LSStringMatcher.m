#import "LSStringMatcher.h"

@interface LSStringMatcher ()

@property (nonatomic, copy) NSString *string;

@end

@implementation LSStringMatcher

- (instancetype)initWithString:(NSString *)string {
    self = [super init];
    if (self) {
        _string = string;
    }
    return self;
}

- (BOOL)matches:(NSString *)string {
    return [self.string isEqualToString:string];
}


#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[LSStringMatcher class]]) {
        return NO;
    }

    return [self.string isEqualToString:((LSStringMatcher *)object).string];
}

- (NSUInteger)hash {
    return self.string.hash;
}

@end
