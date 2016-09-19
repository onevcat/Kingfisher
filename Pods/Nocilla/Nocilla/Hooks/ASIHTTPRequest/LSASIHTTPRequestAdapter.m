#import "LSASIHTTPRequestAdapter.h"

@interface ASIHTTPRequest

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, strong, readonly) NSString *requestMethod;
@property (nonatomic, strong, readonly) NSDictionary *requestHeaders;
@property (nonatomic, strong, readonly) NSData *postBody;

@end

@interface LSASIHTTPRequestAdapter ()
@property (nonatomic, strong) ASIHTTPRequest *request;
@end

@implementation LSASIHTTPRequestAdapter

- (instancetype)initWithASIHTTPRequest:(ASIHTTPRequest *)request {
    self = [super init];
    if (self) {
        _request = request;
    }
    return self;
}

- (NSURL *)url {
    return self.request.url;
}

- (NSString *)method {
    return self.request.requestMethod;
}

- (NSDictionary *)headers {
    return self.request.requestHeaders;
}

- (NSData *)body {
    return self.request.postBody;
}

@end
