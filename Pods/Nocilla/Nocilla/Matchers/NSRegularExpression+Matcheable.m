#import "NSRegularExpression+Matcheable.h"
#import "LSRegexMatcher.h"

@implementation NSRegularExpression (Matcheable)

- (LSMatcher *)matcher {
    return [[LSRegexMatcher alloc] initWithRegex:self];
}

@end
