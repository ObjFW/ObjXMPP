#import "XMPPPresence.h"

@implementation XMPPPresence
+ presence
{
	return [[[self alloc] init] autorelease];
}

+ presenceWithID: (OFString*)ID_
{
	return [[[self alloc] initWithID: ID_] autorelease];
}

+ presenceWithType: (OFString*)type_
{
	return [[[self alloc] initWithType: type_] autorelease];
}

+ presenceWithType: (OFString*)type_
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
	return [super initWithName: @"presence"
			      type: type_
				ID: ID_];
}

- (void)addShow: (OFString*)show
{
	[self addChild: [OFXMLElement elementWithName: @"show"
					  stringValue: show]];
}

- (void)addStatus: (OFString*)status
{
	[self addChild: [OFXMLElement elementWithName: @"status"
					  stringValue: status]];
}

- (void)addPriority: (int8_t)priority
{
	OFString* prio = [OFString stringWithFormat: @"%" @PRId8, priority];
	[self addChild: [OFXMLElement elementWithName: @"priority"
					  stringValue: prio]];
}
@end
