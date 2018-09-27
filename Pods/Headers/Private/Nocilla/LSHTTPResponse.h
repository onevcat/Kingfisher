#import <Foundation/Foundation.h>

@protocol LSHTTPResponse <NSObject>
@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, strong, readonly) NSDictionary *headers;
@property (nonatomic, strong, readonly) NSData *body;
@end
