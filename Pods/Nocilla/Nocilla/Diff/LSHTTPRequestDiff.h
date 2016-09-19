#import <Foundation/Foundation.h>
#import "LSHTTPRequest.h"

@interface LSHTTPRequestDiff : NSObject
@property (nonatomic, assign, readonly, getter = isEmpty) BOOL empty;

- (id)initWithRequest:(id<LSHTTPRequest>)oneRequest andRequest:(id<LSHTTPRequest>)anotherRequest;
@end
