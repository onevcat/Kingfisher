#import <Foundation/Foundation.h>
#import "LSHTTPResponse.h"

@interface LSStubResponse : NSObject<LSHTTPResponse>

@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, strong) NSData *body;
@property (nonatomic, strong, readonly) NSDictionary *headers;

@property (nonatomic, assign, readonly) BOOL shouldFail;
@property (nonatomic, strong, readonly) NSError *error;

- (id)initWithError:(NSError *)error;
- (id)initWithStatusCode:(NSInteger)statusCode;
- (id)initWithRawResponse:(NSData *)rawResponseData;
- (id)initDefaultResponse;
- (void)setHeader:(NSString *)header value:(NSString *)value;
@end
