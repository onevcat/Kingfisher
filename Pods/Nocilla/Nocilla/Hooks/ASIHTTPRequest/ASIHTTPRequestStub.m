#import "ASIHTTPRequestStub.h"
#import "LSStubResponse.h"
#import "LSNocilla.h"
#import "LSASIHTTPRequestAdapter.h"
#import <objc/runtime.h>

@interface ASIHTTPRequestStub ()
@property (nonatomic, strong) LSStubResponse *stubResponse;
@end

@interface ASIHTTPRequestStub (Private)
- (void)failWithError:(NSError *)error;
- (void)requestFinished;
- (void)markAsFinished;
@end

static void const * ASIHTTPRequestStubResponseKey = &ASIHTTPRequestStubResponseKey;

@implementation ASIHTTPRequestStub

- (void)setStubResponse:(LSStubResponse *)stubResponse {
    objc_setAssociatedObject(self, ASIHTTPRequestStubResponseKey, stubResponse, OBJC_ASSOCIATION_RETAIN);
}

- (LSStubResponse *)stubResponse {
    return objc_getAssociatedObject(self, ASIHTTPRequestStubResponseKey);
}

- (int)stub_responseStatusCode {
    return (int)self.stubResponse.statusCode;
}

- (NSData *)stub_responseData {
    return self.stubResponse.body;
}

- (NSDictionary *)stub_responseHeaders {
    return self.stubResponse.headers;
}

- (void)stub_startRequest {
    self.stubResponse = [[LSNocilla sharedInstance] responseForRequest:[[LSASIHTTPRequestAdapter alloc] initWithASIHTTPRequest:(id)self]];

    if (self.stubResponse.shouldFail) {
        [self failWithError:self.stubResponse.error];
    } else {
        [self requestFinished];
    }
    [self markAsFinished];
}

@end