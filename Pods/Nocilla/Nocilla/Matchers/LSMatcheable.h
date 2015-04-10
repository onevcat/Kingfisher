#import <Foundation/Foundation.h>
#import "LSMatcher.h"

@protocol LSMatcheable <NSObject>

- (LSMatcher *)matcher;

@end
