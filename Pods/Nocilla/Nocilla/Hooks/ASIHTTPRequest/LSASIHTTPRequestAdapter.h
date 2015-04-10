#import <Foundation/Foundation.h>
#import "LSHTTPRequest.h"

@class ASIHTTPRequest;

@interface LSASIHTTPRequestAdapter : NSObject<LSHTTPRequest>

- (instancetype)initWithASIHTTPRequest:(ASIHTTPRequest *)request;

@end
