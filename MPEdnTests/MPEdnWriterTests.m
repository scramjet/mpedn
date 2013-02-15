#import "MPEdnWriterTests.h"

#import "MPEdnWriter.h"

#define MPAssertSerialisesOK(value, correct)             \
{                                                        \
  MPEdnWriter *writer = [MPEdnWriter new];               \
                                                         \
  NSString *str = [writer serialiseToEdn: value];        \
                                                         \
  STAssertEqualObjects (str, correct, @"Serialise");     \
}

@implementation MPEdnWriterTests

- (void) testNumbers
{
  MPAssertSerialisesOK (@1, @"1");
  MPAssertSerialisesOK (@-1, @"-1");
  
  MPAssertSerialisesOK ([NSNumber numberWithShort: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithInt: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithUnsignedInt: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithLong: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithLongLong: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithUnsignedLongLong: 1234], @"1234");
  
  MPAssertSerialisesOK ([NSNumber numberWithDouble: 1.1], @"1.1");
  MPAssertSerialisesOK ([NSNumber numberWithFloat: 1.1], @"1.1");
  MPAssertSerialisesOK (@1.1e-5, @"1.1e-05");
  
  // boolean
  MPAssertSerialisesOK (@YES, @"true");
  MPAssertSerialisesOK (@NO, @"false");
  
  // characters
  // http://www.cocoabuilder.com/archive/cocoa/136956-nsnumber-is-completely-broken.html
  MPAssertSerialisesOK (@'a', @"\\a");
  NSLog (@"********** %s", [[NSNumber numberWithChar: '\n'] objCType]);
  NSLog (@"********** %@", [[NSNumber numberWithChar: '\n'] class]);
  NSLog (@"********** %li", CFNumberGetType ((CFNumberRef)[NSNumber numberWithChar: '\n']));

  MPAssertSerialisesOK ([NSNumber numberWithChar: '\n'], @"\\\n");
}

- (void) testNil
{
  MPAssertSerialisesOK (nil, @"nil");
  MPAssertSerialisesOK ([NSNull null], @"nil");
}

@end
