#import "LSMatcher.h"

@implementation LSMatcher

- (BOOL)matches:(NSString *)string {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"[LSMatcher matches:] is an abstract method" userInfo:nil];
}

@end
