#import <Foundation/Foundation.h>

NSNumber *MPEdnTagAsCharacter (NSNumber *number);
BOOL MPEdnIsCharacter (NSNumber *number);

@interface MPEdnWriter : NSObject
{
  NSMutableString *outputStr;
}

- (NSString *) serialiseToEdn: (id) value;

@end
