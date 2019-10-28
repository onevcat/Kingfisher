#import <Foundation/Foundation.h>
#import "LSStubResponse.h"
#import "LSHTTPRequest.h"


@class LSMatcher;
@class LSStubRequest;
@class LSStubResponse;

@interface LSStubRequest : NSObject
@property (nonatomic, strong, readonly) NSString *method;
@property (nonatomic, strong, readonly) LSMatcher *urlMatcher;
@property (nonatomic, strong, readonly) NSDictionary *headers;
@property (nonatomic, strong, readwrite) LSMatcher *body;

@property (nonatomic, strong) LSStubResponse *response;

- (instancetype)initWithMethod:(NSString *)method url:(NSString *)url;
- (instancetype)initWithMethod:(NSString *)method urlMatcher:(LSMatcher *)urlMatcher;

- (void)setHeader:(NSString *)header value:(NSString *)value;

- (BOOL)matchesRequest:(id<LSHTTPRequest>)request;
@end
