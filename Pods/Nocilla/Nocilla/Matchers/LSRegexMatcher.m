#import "LSRegexMatcher.h"

@interface LSRegexMatcher ()
@property (nonatomic, strong) NSRegularExpression *regex;
@end

@implementation LSRegexMatcher

- (instancetype)initWithRegex:(NSRegularExpression *)regex {
    self = [super init];
    if (self) {
        _regex = regex;
    }
    return self;
}

- (BOOL)matches:(NSString *)string {
    return [self.regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)] > 0;
}

@end
