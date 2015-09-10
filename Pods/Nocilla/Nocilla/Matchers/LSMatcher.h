#import <Foundation/Foundation.h>

@interface LSMatcher : NSObject

- (BOOL)matches:(NSString *)string;

- (BOOL)matchesData:(NSData *)data;

@end
