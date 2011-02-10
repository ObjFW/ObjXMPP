#import "XMPPStanza.h"

@implementation XMPPStanza
@synthesize from;
@synthesize to;
@synthesize type;
@synthesize ID;

+ stanzaWithName: (OFString*)name
{
	return [[[self alloc] initWithName: name] autorelease];
}

+ stanzaWithElement: (OFXMLElement*)elem {
	return [[[self alloc] initWithElement: elem] autorelease];
}

- initWithName: (OFString*)name_
{
	if (!([name_ isEqual: @"iq"] ||
	      [name_ isEqual: @"message"] ||
	      [name_ isEqual: @"presence"]))
		of_log(@"Invalid stanza name!");

	self = [super initWithName: name_];
	[self setDefaultNamespace: @"jabber:client"];

	from = [[OFString alloc] init];
	to = [[OFString alloc] init];
	type = [[OFString alloc] init];
	ID = [[OFString alloc] init];

	return self;
}

- initWithElement: (OFXMLElement*)elem
{
	self = [super initWithName: elem.name
			 namespace: elem.namespace];

	from = [[OFString alloc] init];
	to = [[OFString alloc] init];
	type = [[OFString alloc] init];
	ID = [[OFString alloc] init];

	OFXMLAttribute *attr;

	for (attr in elem.attributes) {
		if ([attr.name isEqual: @"from"]) {
			[self setFrom: [attr stringValue]];
		} else if ([attr.name isEqual: @"to"]) {
			[self setTo: [attr stringValue]];
		} else if ([attr.name isEqual: @"type"]) {
			[self setType: [attr stringValue]];
		} else if ([attr.name isEqual: @"id"]) {
			[self setID: [attr stringValue]];
		} else {
			[self addAttribute: attr];
		}
	}

	OFXMLElement *el;

	for (el in elem.children) {
		[self addChild: el];
	}

	return self;
}

- (void)dealloc
{
	[from release];
	[to release];
	[type release];
	[ID release];

	[super dealloc];
}

- (void)setFrom: (OFString*)from_
{
	OFString* old = from;
	from = [from_ copy];
	[old release];
	[self addAttributeWithName: @"from" stringValue: from_];
}

- (void)setTo: (OFString*)to_
{
	OFString* old = to;
	to = [to_ copy];
	[old release];
	[self addAttributeWithName: @"to" stringValue: to];
}

- (void)setType: (OFString*)type_
{
	OFString* old = type;
	type = [type_ copy];
	[old release];
	[self addAttributeWithName: @"type" stringValue: type];
}

- (void)setID: (OFString*)ID_
{
	OFString* old = ID;
	ID = [ID_ copy];
	[old release];
	[self addAttributeWithName: @"id" stringValue: ID];
}
@end

@implementation XMPPIQ
+ IQWithType: (OFString*)type_
	  ID: (OFString*)ID_
{
	if (!([type_ isEqual: @"get"] ||
	      [type_ isEqual: @"set"] ||
	      [type_ isEqual: @"result"] ||
	      [type_ isEqual: @"error"]))
		of_log(@"Invalid IQ type!");

	id ret;
	ret = [[[self alloc] initWithName: @"iq"] autorelease];
	[ret setType: type_];
	[ret setID: ID_];
	return ret;
}
@end

@implementation XMPPMessage
+ message
{
	return [self messageWithType: nil ID: nil];
}

+ messageWithID: (OFString*)ID_
{
	return [self messageWithType: nil ID: ID_];
}

+ messageWithType: (OFString*)type_
{
	return [self messageWithType: type_ ID: nil];
}

+ messageWithType: (OFString*)type_
	       ID: (OFString*)ID_
{
	id ret;
	ret = [[[self alloc] initWithName: @"message"] autorelease];
	if (type_)
		[ret setType: type_];
	if (ID_)
		[ret setID: ID_];
	return ret;
}

- (void)addBody: (OFString*)body
{
	[self addChild: [OFXMLElement elementWithName: @"body"
					  stringValue: body]];
}
@end

@implementation XMPPPresence
+ presence
{
	return [self presenceWithType: nil ID: nil];
}

+ presenceWithID: (OFString*)ID_
{
	return [self presenceWithType: nil ID: ID_];
}

+ presenceWithType: (OFString*)type_
{
	return [self presenceWithType: type_ ID: nil];
}

+ presenceWithType: (OFString*)type_
		ID: (OFString*)ID_
{
	id ret;
	ret = [[[self alloc] initWithName: @"presence"] autorelease];
	if (type_)
		[ret setType: type_];
	if (ID_)
		[ret setID: ID_];
	return ret;
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

- (void)addPriority: (char)priority
{
	OFString* prio = [OFString stringWithFormat: @"%d", priority];
	[self addChild: [OFXMLElement elementWithName: @"priority"
					  stringValue: prio]];
}
@end
