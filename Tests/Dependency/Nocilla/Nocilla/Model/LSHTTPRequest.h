#import <Foundation/Foundation.h>

@protocol LSHTTPRequest <NSObject>

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, strong, readonly) NSString *method;
@property (nonatomic, strong, readonly) NSDictionary *headers;
@property (nonatomic, strong, readonly) NSData *body;

@end
