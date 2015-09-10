#import <Foundation/Foundation.h>

@class LSStubResponse;
@class LSStubResponseDSL;

@protocol LSHTTPBody;

typedef LSStubResponseDSL *(^ResponseWithBodyMethod)(id<LSHTTPBody>);
typedef LSStubResponseDSL *(^ResponseWithHeaderMethod)(NSString *, NSString *);
typedef LSStubResponseDSL *(^ResponseWithHeadersMethod)(NSDictionary *);
typedef LSStubResponseDSL *(^ResponseVoidMethod)();

@interface LSStubResponseDSL : NSObject
- (id)initWithResponse:(LSStubResponse *)response;

@property (nonatomic, strong, readonly) ResponseWithHeaderMethod withHeader;
@property (nonatomic, strong, readonly) ResponseWithHeadersMethod withHeaders;
@property (nonatomic, strong, readonly) ResponseWithBodyMethod withBody;

@property (nonatomic, strong, readonly) ResponseVoidMethod delay;
@property (nonatomic, strong, readonly) ResponseVoidMethod go;

@end
