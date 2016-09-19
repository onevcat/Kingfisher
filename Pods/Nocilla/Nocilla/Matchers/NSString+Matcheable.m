#import "NSString+Matcheable.h"
#import "LSStringMatcher.h"

@implementation NSString (Matcheable)

- (LSMatcher *)matcher {
    return [[LSStringMatcher alloc] initWithString:self];
}

@end
