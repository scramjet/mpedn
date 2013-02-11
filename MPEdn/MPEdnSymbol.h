#import <Foundation/Foundation.h>

@interface MPEdnSymbol : NSObject
{
  NSString *name;
}

@property (readonly) NSString *name;

+ (MPEdnSymbol *) symbolWithName: (NSString *) name;

@end
