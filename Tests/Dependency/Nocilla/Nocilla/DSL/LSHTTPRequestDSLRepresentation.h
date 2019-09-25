#import <Foundation/Foundation.h>
#import "LSHTTPRequest.h"

@interface LSHTTPRequestDSLRepresentation : NSObject
- (id)initWithRequest:(id<LSHTTPRequest>)request;
@end
