@interface ASIHTTPRequestStub : NSObject
- (NSInteger)stub_responseStatusCode;
- (NSData *)stub_responseData;
- (NSDictionary *)stub_responseHeaders;
- (void)stub_startRequest;
@end
