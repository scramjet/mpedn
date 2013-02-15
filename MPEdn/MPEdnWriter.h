#import <Foundation/Foundation.h>

@interface MPEdnWriter : NSObject
{
  NSMutableString *outputStr;
}

- (NSString *) serialiseToEdn: (id) value;

@end
