#import "LSStubRequestDSL.h"
#import "LSStubResponseDSL.h"
#import "LSStubRequest.h"
#import "LSNocilla.h"

@interface LSStubRequestDSL ()
@property (nonatomic, strong) LSStubRequest *request;
@end

@implementation LSStubRequestDSL

- (id)initWithRequest:(LSStubRequest *)request {
    self = [super init];
    if (self) {
        _request = request;
    }
    return self;
}
- (WithHeadersMethod)withHeaders {
    return ^(NSDictionary *headers) {
        for (NSString *header in headers) {
            NSString *value = [headers objectForKey:header];
            [self.request setHeader:header value:value];
        }
        return self;
    };
}

- (WithHeaderMethod)withHeader {
    return ^(NSString * header, NSString * value) {
        [self.request setHeader:header value:value];
        return self;
    };
}

- (AndBodyMethod)withBody {
    return ^(id<LSMatcheable> body) {
        self.request.body = body.matcher;
        return self;
    };
}

- (AndReturnMethod)andReturn {
    return ^(NSInteger statusCode) {
        self.request.response = [[LSStubResponse alloc] initWithStatusCode:statusCode];
        LSStubResponseDSL *responseDSL = [[LSStubResponseDSL alloc] initWithResponse:self.request.response];
        return responseDSL;
    };
}

- (AndReturnRawResponseMethod)andReturnRawResponse {
    return ^(NSData *rawResponseData) {
        self.request.response = [[LSStubResponse alloc] initWithRawResponse:rawResponseData];
        LSStubResponseDSL *responseDSL = [[LSStubResponseDSL alloc] initWithResponse:self.request.response];
        return responseDSL;
    };
}

- (AndFailWithErrorMethod)andFailWithError {
    return ^(NSError *error) {
        self.request.response = [[LSStubResponse alloc] initWithError:error];
    };
}

@end

LSStubRequestDSL * stubRequest(NSString *method, id<LSMatcheable> url) {
    LSStubRequest *request = [[LSStubRequest alloc] initWithMethod:method urlMatcher:url.matcher];
    LSStubRequestDSL *dsl = [[LSStubRequestDSL alloc] initWithRequest:request];
    [[LSNocilla sharedInstance] addStubbedRequest:request];
    return dsl;
}
