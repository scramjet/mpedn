#import "MPEdnTests.h"

#import "MPEDN.h"

#define MPAssertParseError(expr, message)  \
{                                          \
  MPEdnParser *parser = [MPEdnParser new]; \
                                           \
  id value = [parser parseString: expr];   \
                                           \
  STAssertNil (value, message);            \
  STAssertNotNil (parser.error, message);  \
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
  STAssertEqualObjects ([@"1" ednStringToObject], @1, @"Integer");
  STAssertEqualObjects ([@"+1" ednStringToObject], @1, @"Integer");
  STAssertEqualObjects ([@"-1" ednStringToObject], @-1, @"Integer");
  STAssertEqualObjects ([@" 1 " ednStringToObject], @1, @"Integer (whitespace)");
  
  // double
  STAssertEqualObjects ([@"1.2" ednStringToObject], @1.2, @"Float");
  STAssertEqualObjects ([@"1.2e4" ednStringToObject], @1.2e4, @"Float");
  STAssertEqualObjects ([@"-42.2e-2" ednStringToObject], @-42.2e-2, @"Float");
  STAssertEqualObjects ([@".2" ednStringToObject], @.2, @"Float");
  
  // does not allow M or N (not implemented)
  MPAssertParseError (@"1.0M", @"Float");
  
  // errors
  MPAssertParseError (@".", @"Float");
  MPAssertParseError (@"1.", @"Float");
  MPAssertParseError (@"-+1", @"Float");
  MPAssertParseError (@"1e", @"Float");
}

- (void) testWhitespaceAndComments
{
  STAssertEqualObjects ([@"\t 1" ednStringToObject], @1, @"Tabs and space");
  STAssertEqualObjects ([@"\n 1" ednStringToObject], @1, @"Newlines and space");
  STAssertEqualObjects ([@"\r\n 1" ednStringToObject], @1, @"Newlines and space");
  
  STAssertEqualObjects ([@" ; comment\n 1" ednStringToObject], @1, @"Comment and space");
  
  // errors
  MPAssertParseError (@"; comment", @"Comment with no value");
}

@end
