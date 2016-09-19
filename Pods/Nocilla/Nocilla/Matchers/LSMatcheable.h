#import <Foundation/Foundation.h>

@class LSMatcher;

@protocol LSMatcheable <NSObject>

- (LSMatcher *)matcher;

@end
