#import "LSMatcher.h"

@implementation LSMatcher

- (BOOL)matches:(NSString *)string {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"[LSMatcher matches:] is an abstract method" userInfo:nil];
}

- (BOOL)matchesData:(NSData *)data {
    return [self matches:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
}


#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"[LSMatcher isEqual:] is an abstract method" userInfo:nil];
}

- (NSUInteger)hash {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"[LSMatcher hash] an abstract method" userInfo:nil];
}

@end
