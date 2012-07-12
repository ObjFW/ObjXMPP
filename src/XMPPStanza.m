/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://webkeks.org/git/?p=objxmpp.git
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice is present in all copies.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#import "XMPPStanza.h"
#import "XMPPJID.h"
#import "namespaces.h"

@implementation XMPPStanza
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

+ stanzaWithElement: (OFXMLElement*)element
{
	return [[[self alloc] initWithElement: element] autorelease];
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
	self = [super initWithName: name_
			 namespace: XMPP_NS_CLIENT];

	@try {
		if (![name_ isEqual: @"iq"] && ![name_ isEqual: @"message"] &&
		    ![name_ isEqual: @"presence"])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: [self class]
				      selector: _cmd];

		[self setDefaultNamespace: XMPP_NS_CLIENT];
		[self setPrefix: @"stream"
		   forNamespace: XMPP_NS_STREAM];

		if (type_ != nil)
			[self setType: type_];

		if (ID_ != nil)
			[self setID: ID_];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithElement: (OFXMLElement*)element
{
	self = [super initWithElement: element];

	@try {
		OFXMLAttribute *attribute;

		if ((attribute = [element attributeForName: @"from"]))
			[self setFrom:
			    [XMPPJID JIDWithString: [attribute stringValue]]];

		if ((attribute = [element attributeForName: @"to"]))
			[self setTo:
			    [XMPPJID JIDWithString: [attribute stringValue]]];

		if ((attribute = [element attributeForName: @"type"]))
			[self setType: [attribute stringValue]];

		if ((attribute = [element attributeForName: @"id"]))
			[self setID: [attribute stringValue]];
	} @catch (id e) {
		[self release];
		@throw e;
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

- (void)setFrom: (XMPPJID*)from_
{
	XMPPJID *old = from;
	from = [from_ copy];
	[old release];

	[self removeAttributeForName: @"from"];

	if (from_ != nil)
		[self addAttributeWithName: @"from"
			       stringValue: [from_ fullJID]];
}

- (XMPPJID*)from
{
	return [[from copy] autorelease];
}

- (void)setTo: (XMPPJID*)to_
{
	XMPPJID *old = to;
	to = [to_ copy];
	[old release];

	[self removeAttributeForName: @"to"];

	if (to_ != nil)
		[self addAttributeWithName: @"to"
			       stringValue: [to_ fullJID]];
}

- (XMPPJID*)to
{
	return [[to copy] autorelease];
}

- (void)setType: (OFString*)type_
{
	OFString *old = type;
	type = [type_ copy];
	[old release];

	[self removeAttributeForName: @"type"];

	if (type_ != nil)
		[self addAttributeWithName: @"type"
			       stringValue: type];
}

- (OFString*)type
{
	return [[type copy] autorelease];
}

- (void)setID: (OFString*)ID_
{
	OFString *old = ID;
	ID = [ID_ copy];
	[old release];

	[self removeAttributeForName: @"id"];

	if (ID_ != nil)
		[self addAttributeWithName: @"id"
			       stringValue: ID_];
}

- (OFString*)ID
{
	return [[ID copy] autorelease];
}

- (void)setLanguage: (OFString*)language_
{
	OFString *old = language;
	language = [language_ copy];
	[old release];

	[self removeAttributeForName: @"lang"
			   namespace: @"http://www.w3.org/XML/1998/namespace"];

	if (language_ != nil)
		[self addAttributeWithName: @"lang"
				 namespace: @"http://www.w3.org/XML/1998/"
					    @"namespace"
			       stringValue: language_];
}

- (OFString*)language
{
	return [[language copy] autorelease];
}
@end
