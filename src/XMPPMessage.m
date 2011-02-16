#import "XMPPMessage.h"

@implementation XMPPMessage
+ message
{
	return [[[self alloc] init] autorelease];
}

+ messageWithID: (OFString*)ID_
{
	return [[[self alloc] initWithID: ID_] autorelease];
}

+ messageWithType: (OFString*)type_
{
	return [[[self alloc] initWithType: type_] autorelease];
}

+ messageWithType: (OFString*)type_
	       ID: (OFString*)ID_
{
	return [[[self alloc] initWithType: type_
					ID: ID_] autorelease];
}

- init
{
	return [self initWithType: nil
			       ID: nil];
}

- initWithID: (OFString*)ID_
{
	return [self initWithType: nil
			       ID: ID_];
}

- initWithType: (OFString*)type_
{
	return [self initWithType: type_
			       ID: nil];
}

- initWithType: (OFString*)type_
	    ID: (OFString*)ID_
{
	return [super initWithName: @"message"
			      type: type_
				ID: ID_];
}

- (void)addBody: (OFString*)body
{
	[self addChild: [OFXMLElement elementWithName: @"body"
					  stringValue: body]];
}
@end
