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

+ stanzaWithName: (OFString*)name
	    type: (OFString*)type_
{
	return [[[self alloc] initWithName: name
				      type: type_] autorelease];
}

+ stanzaWithName: (OFString*)name
	      ID: (OFString*)ID_
{
	return [[[self alloc] initWithName: name
					ID: ID_] autorelease];
}

+ stanzaWithName: (OFString*)name
	    type: (OFString*)type_
	      ID: (OFString*)ID_
{
	return [[[self alloc] initWithName: name
				      type: type_
					ID: ID_] autorelease];
}

+ stanzaWithElement: (OFXMLElement*)elem {
	return [[[self alloc] initWithElement: elem] autorelease];
}

- initWithName: (OFString*)name_
{
	return [self initWithName: name_
			     type: nil
			       ID: nil];
}

- initWithName: (OFString*)name_
	  type: (OFString*)type_
{
	return [self initWithName: name_
			     type: type_
			       ID: nil];
}

- initWithName: (OFString*)name_
	    ID: (OFString*)ID_
{
	return [self initWithName: name_
			     type: nil
			       ID: ID_];
}

- initWithName: (OFString*)name_
	  type: (OFString*)type_
	    ID: (OFString*)ID_
{
	if (!([name_ isEqual: @"iq"] ||
	      [name_ isEqual: @"message"] ||
	      [name_ isEqual: @"presence"]))
		of_log(@"Invalid stanza name!");

	self = [super initWithName: name_];
	[self setDefaultNamespace: @"jabber:client"];
	if (type_)
		[self setType: type_];
	if (ID_)
		[self setID: ID_];
	return self;
}

- initWithElement: (OFXMLElement*)elem
{
	self = [super initWithName: elem.name
			 namespace: elem.namespace];

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
	[self addAttributeWithName: @"id"
		       stringValue: ID];
}
@end
