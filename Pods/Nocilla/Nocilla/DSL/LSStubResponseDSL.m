#import "LSStubResponseDSL.h"
#import "LSStubResponse.h"
#import "LSHTTPBody.h"

@interface LSStubResponseDSL ()
@property (nonatomic, strong) LSStubResponse *response;
@end

@implementation LSStubResponseDSL
- (id)initWithResponse:(LSStubResponse *)response {
    self = [super init];
    if (self) {
        _response = response;
    }
    return self;
}
- (ResponseWithHeaderMethod)withHeader {
    return ^(NSString * header, NSString * value) {
        [self.response setHeader:header value:value];
        return self;
    };
}

- (ResponseWithHeadersMethod)withHeaders; {
    return ^(NSDictionary *headers) {
        for (NSString *header in headers) {
            NSString *value = [headers objectForKey:header];
            [self.response setHeader:header value:value];
        }
        return self;
    };
}

- (ResponseWithBodyMethod)withBody {
    return ^(id<LSHTTPBody> body) {
        self.response.body = [body data];
        return self;
    };
}

- (ResponseVoidMethod)delay {
    return ^{
        [self.response delay];
        return self;
    };
}

- (ResponseVoidMethod)go {
    return ^{
        [self.response go];
        return self;
    };
}

@end
