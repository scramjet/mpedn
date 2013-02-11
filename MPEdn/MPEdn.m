#import "MPEDN.h"

// A token is one of these or just a single character.
typedef enum
{
  TOKEN_NONE = 0xF00000,  // NB: outside UTF-16 range
  TOKEN_ERROR,
  TOKEN_SET_OPEN,
  TOKEN_NUMBER
} Token;

@implementation MPEdnParser

- (void) reset
{
  inputStr = nil;
  inputStrLen = 0;
  startIdx = 0;
  endIdx = 0;
  token = TOKEN_NONE;
  tokenValue = nil;
  error = nil;
}

- (void) raiseError: (NSInteger) code message: (NSString *) message, ...
{
  va_list args;
  va_start (args, message);
  
  NSString *desc = [[NSString alloc] initWithFormat: message arguments: args];

  va_end (args);

  token = TOKEN_ERROR;
  
  error = [[NSError alloc] initWithDomain: @"MPEdn" code: code
                                 userInfo: @{NSLocalizedDescriptionKey : desc,
                                             NSUnderlyingErrorKey : error ? error : [NSNull null]}];
}

- (NSError *) error
{
  return error;
}

#pragma mark - Tokeniser

static BOOL is_sym_punct (unichar ch)
{
  // NB: '/' is added to the specified EDN set of punctuation allowed in
  // symbol names. The check for its valid use is done by the parser.
  return (ch >= '!' && ch <= '_' &&
          (ch == '!' || ch == '$' || ch == '%' || ch == '&' || ch == '*' ||
           ch == '+' || ch == '-' || ch == '.' || ch == '=' || ch == '?' ||
           ch == '_' || ch == '/'));
}

- (unichar) advanceStartIdx
{
  startIdx++;
  
  return (startIdx < inputStrLen) ? [inputStr characterAtIndex: startIdx] : 0;
}

- (unichar) advanceEndIdx
{
  endIdx++;
  
  return (endIdx < inputStrLen) ? [inputStr characterAtIndex: endIdx] : 0;
}

- (unichar) skipSpaceAndComments
{
  if (startIdx < inputStrLen)
  {
    unichar ch = [inputStr characterAtIndex: startIdx];
    
    // skip white space and comments
    while ((isspace (ch) || ch == ';') && startIdx < inputStrLen)
    {
      if (ch == ';')
      {
        while (ch != '\n' && startIdx < inputStrLen)
          ch = [self advanceStartIdx];
        
        ch = [self advanceStartIdx];         // skip \n
      } else
      {
        ch = [self advanceStartIdx];
      }
    }

    endIdx = startIdx;

    return ch;
  } else
  {
    return 0;
  }
}

// NB: this does not handle symbols and keywords containing Unicode code points
// > 0xFFFF (i.e. characters that require representation using UTF-16 surrogate
// pairs). It *does* however support all Unicode points in strings.
- (void) nextToken
{
  tokenValue = nil;
  unichar ch = [self skipSpaceAndComments];

  if (startIdx < inputStrLen)
  {
    unichar lookahead =
      startIdx + 1 < inputStrLen ? [inputStr characterAtIndex: startIdx + 1] : 0;

    if (ch == '{' || ch == '[' || ch == '(')
    {
      token = ch;
      endIdx = startIdx + 1;
    } else if (ch == '"')
    {
      [self readStringToken];
    } else if (isdigit (ch))
    {
      [self readNumberToken];
    } else if (ch == '+' || ch == '-' || ch == '.')
    {
      if (isalpha (lookahead))
        [self readNameToken];
      else
        [self readNumberToken];
    } else if (ch == '#')
    {
      if (lookahead == '{')
      {
        token = TOKEN_SET_OPEN;
        endIdx = startIdx + 2;
      } else if (lookahead == '_')
      {
        endIdx = startIdx + 2;
        [self nextToken];
        [self parseExpr];
        [self nextToken];
      } else
      {
        [self readTagName];
      }
    } else
    {
      [self readNameToken];
    }
  }
}

- (void) readNumberToken
{
  unichar ch = [inputStr characterAtIndex: endIdx];
  BOOL isFloat = NO;
  
  if (ch == '+' || ch == '-')
    ch = [self advanceEndIdx];
  
  while (isdigit (ch))
    ch = [self advanceEndIdx];
  
  if (ch == '.')
  {
    isFloat = YES;
    
    do
    {
      ch = [self advanceEndIdx];
    } while (isdigit (ch));
  }

  if (ch == 'e' || ch == 'E')
  {
    ch = [self advanceEndIdx];

    if (ch == '+' || ch == '-')
      ch = [self advanceEndIdx];
    
    while (isdigit (ch))
      ch = [self advanceEndIdx];
  }

  if (ch == 'm' || ch == 'M' || ch == 'n' || ch == 'N')
  {
    ch = [self advanceEndIdx];
    
    [self raiseError: ERROR_UNSUPPORTED_FEATURE
             message: @"M and N number suffixes are not supported"];
  }
  
  // NB: NSNumberFormatter throws exceptions on error and may or may not parse
  // floats according to the spec. Using strtod and and strtol instead.
  NSString *numberStr =
    [inputStr substringWithRange: NSMakeRange (startIdx, endIdx - startIdx)];
                          
  const char *numberStrUtf8 =
    [numberStr cStringUsingEncoding: NSUTF8StringEncoding];
  
  char *numberStrEnd = (char *)numberStrUtf8;
  
  if (isFloat)
  {
    double number = strtod (numberStrUtf8, &numberStrEnd);
    
    if (numberStrEnd - numberStrUtf8 == endIdx - startIdx)
    {
      if ([numberStr characterAtIndex: [numberStr length] - 1] == '.')
      {
        // strtod happily allows "1." as a legal number
        [self raiseError: ERROR_INVALID_NUMBER
                 message: @"Trailing '.' on number: \"%@\"", numberStr];
      } else
      {
        token = TOKEN_NUMBER;
        tokenValue = [NSNumber numberWithDouble: number];
      }
    } else
    {
      [self raiseError: ERROR_INVALID_NUMBER
               message: @"Invalid floating point number: \"%@\"", numberStr];
    }
  } else
  {
    long int number = strtol (numberStrUtf8, &numberStrEnd, 10);
    
    if (numberStrEnd - numberStrUtf8 == endIdx - startIdx)
    {
      token = TOKEN_NUMBER;
      tokenValue = [NSNumber numberWithLong: number];
    } else
    {
      [self raiseError: ERROR_INVALID_NUMBER
               message: @"Invalid integer: \"%@\"", numberStr];
    }
  }
}

- (void) readNameToken
{
  
}

- (void) readStringToken
{
  
}

- (void) readTagName
{
  
}

#pragma mark - Parser

- (BOOL) complete
{
  [self skipSpaceAndComments];
  
  return startIdx >= inputStrLen;
}

- (id) parseString: (NSString *) str
{
  [self reset];
  
  inputStr = str;
  inputStrLen = [inputStr length];
  
  id value = [self parseNextValue];
  
  if (self.complete)
  {
    return value;
  } else
  {
    startIdx = endIdx = inputStrLen;

    [self raiseError: ERROR_MULTIPLE_VALUES
             message: @"More than one value supplied when only one expected"];
    
    return nil;
  }
}

- (id) parseNextValue
{
  [self nextToken];
  
  id value = [self parseExpr];
  
  startIdx = endIdx;
  
  return value;
}

- (id) parseExpr
{
  switch (token)
  {
    case TOKEN_NUMBER:
      return tokenValue;
    case TOKEN_ERROR:
    case TOKEN_SET_OPEN:
      return nil;
    default:
    {
      [self raiseError: ERROR_NO_EXPRESSION
               message: @"No value found in expression"];
      return nil;
    }
  }
}

@end

@implementation NSString (MPEdn)

- (id) ednStringToObject
{
  MPEdnParser *parser = [MPEdnParser new];
  
  return [parser parseString: self];
}

@end

@implementation NSObject (MPEdn)

- (NSString *) objectToEdnString
{
  return nil;
}

@end

