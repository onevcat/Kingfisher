#import <Foundation/Foundation.h>

@interface ASIHTTPRequestStub : NSObject
- (int)stub_responseStatusCode;
- (NSData *)stub_responseData;
- (NSDictionary *)stub_responseHeaders;
- (void)stub_startRequest;
@end
