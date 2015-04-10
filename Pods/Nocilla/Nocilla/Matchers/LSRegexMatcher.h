#import "LSMatcher.h"

@interface LSRegexMatcher : LSMatcher

- (instancetype)initWithRegex:(NSRegularExpression *)regex;

@end
