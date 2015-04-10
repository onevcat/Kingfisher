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

@end
