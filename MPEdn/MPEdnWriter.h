#import <Foundation/Foundation.h>

NSNumber *MPEdnTagAsCharacter (NSNumber *number);
BOOL MPEdnIsCharacter (NSNumber *number);

@interface MPEdnWriter : NSObject
{
  NSMutableString *outputStr;
  BOOL useKeywordsInMaps;
}

@property (readwrite) BOOL useKeywordsInMaps;

- (NSString *) serialiseToEdn: (id) value;

@end
