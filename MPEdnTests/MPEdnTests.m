#import "MPEdnTests.h"

#import "MPEDN.h"

#define MPAssertParseOK(expr, correctValue, message)    \
{                                          \
  MPEdnParser *parser = [MPEdnParser new]; \
                                           \
  id value = [parser parseString: expr];   \
                                           \
  STAssertEqualObjects (value, correctValue, message);         \
  STAssertNil (parser.error, message);     \
  STAssertTrue (parser.complete, message); \
}

#define MPAssertParseError(expr, message)  \
{                                          \
  MPEdnParser *parser = [MPEdnParser new]; \
                                           \
  id value = [parser parseString: expr];   \
                                           \
  STAssertNil (value, message);            \
  STAssertNotNil (parser.error, message);  \
  STAssertTrue (parser.complete, message); \
}

@implementation MPEdnTests

//- (void)setUp
//{
//    [super setUp];
//    
//    // Set-up code here.
//}
//
//- (void)tearDown
//{
//    // Tear-down code here.
//    
//    [super tearDown];
//}

- (void) testNumbers
{
  // int
  MPAssertParseOK (@"1", @1, @"Integer");
  MPAssertParseOK (@"+1", @1, @"Integer");
  MPAssertParseOK (@"-1", @-1, @"Integer");
  MPAssertParseOK (@" 1 ", @1, @"Integer (whitespace)");
  
  // double
  MPAssertParseOK (@"1.2", @1.2, @"Float");
  MPAssertParseOK (@"1.2e4", @1.2e4, @"Float");
  MPAssertParseOK (@"-42.2e-2", @-42.2e-2, @"Float");
  MPAssertParseOK (@".2", @.2, @"Float");
  
  // does not allow M or N (not implemented)
  MPAssertParseError (@"1.0M", @"Float");
  
  // errors
  MPAssertParseError (@".", @"Float");
  MPAssertParseError (@"1.", @"Float");
  MPAssertParseError (@"1e", @"Float");
  
  // do not allow more than one value for parseString
  MPAssertParseError (@"1 1", @"More than one value");
}

- (void) testWhitespaceAndComments
{
  MPAssertParseOK (@"\t 1", @1, @"Tabs and space");
  MPAssertParseOK (@"\n 1", @1, @"Newlines and space");
  MPAssertParseOK (@"\r\n 1", @1, @"Newlines and space");
  
  STAssertEqualObjects ([@" ; comment\n 1" ednStringToObject], @1, @"Comment and space");
  
  // errors
  MPAssertParseError (@"; comment", @"Comment with no value");
}

@end
