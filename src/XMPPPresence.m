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

#include <assert.h>

#import "XMPPPresence.h"
#import "namespaces.h"

// This provides us with sortable values for show values
static int show_to_int(OFString *show)
{
	if ([show isEqual: @"chat"]) return 0;
	if (show == nil) return 1; // available
	if ([show isEqual: @"away"]) return 2;
	if ([show isEqual: @"dnd"]) return 3;
	if ([show isEqual: @"xa"]) return 4;

	assert(0);
}

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

- initWithElement: (OFXMLElement*)element
{
	self = [super initWithElement: element];

	@try {
		OFXMLElement *subElement;

		if ((subElement = [element elementForName: @"show"
						namespace: XMPP_NS_CLIENT]))
			[self setShow: [subElement stringValue]];

		if ((subElement = [element elementForName: @"status"
						namespace: XMPP_NS_CLIENT]))
			[self setStatus: [subElement stringValue]];

		if ((subElement = [element elementForName: @"priority"
						namespace: XMPP_NS_CLIENT]))
			[self setPriority:
			    [OFNumber numberWithIntMax:
				[[subElement stringValue] decimalValue]]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}


- (void)dealloc
{
	[status release];
	[show release];
	[priority release];

	[super dealloc];
}

- (OFString*)type
{
	if (type == nil)
		return @"available";

	return [[type copy] autorelease];
}

- (void)setShow: (OFString*)show_
{
	OFXMLElement *oldShow = [self elementForName: @"show"
					   namespace: XMPP_NS_CLIENT];

	if (oldShow != nil)
		[self removeChild: oldShow];

	if (show_ != nil)
		[self addChild: [OFXMLElement elementWithName: @"show"
						    namespace: XMPP_NS_CLIENT
						  stringValue: show_]];

	OF_SETTER(show, show_, YES, 1);
}

- (OFString*)show
{
	return [[show copy] autorelease];
}

- (void)setStatus: (OFString*)status_
{
	OFXMLElement *oldStatus = [self elementForName: @"status"
					     namespace: XMPP_NS_CLIENT];

	if (oldStatus != nil)
		[self removeChild: oldStatus];

	if (status_ != nil)
		[self addChild: [OFXMLElement elementWithName: @"status"
						    namespace: XMPP_NS_CLIENT
						  stringValue: status_]];

	OF_SETTER(status, status_, YES, 1);
}

- (OFString*)status
{
	return [[status copy] autorelease];
}

- (void)setPriority: (OFNumber*)priority_
{
	intmax_t prio = [priority_ intMaxValue];

	if ((prio < -128) || (prio > 127))
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	OFXMLElement *oldPriority = [self elementForName: @"priority"
					       namespace: XMPP_NS_CLIENT];

	if (oldPriority != nil)
		[self removeChild: oldPriority];

	OFString* priority_s =
	    [OFString stringWithFormat: @"%" @PRId8, [priority_ int8Value]];
	[self addChild: [OFXMLElement elementWithName: @"priority"
					    namespace: XMPP_NS_CLIENT
					  stringValue: priority_s]];

	OF_SETTER(priority, priority_, YES, 1);
}

- (OFString*)priority
{
	return [[priority copy] autorelease];
}

- (of_comparison_result_t)compare: (id <OFComparing>)object
{
	XMPPPresence *otherPresence;
	OFString *otherShow;
	of_comparison_result_t priorityOrder;

	if (object == self)
		return OF_ORDERED_SAME;

	if (![object isKindOfClass: [XMPPPresence class]])
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	otherPresence = (XMPPPresence*)object;

	priorityOrder = [priority compare: [otherPresence priority]];

	if (priorityOrder != OF_ORDERED_SAME)
		return priorityOrder;

	otherShow = [otherPresence show];
	if ([show isEqual: otherShow])
		return OF_ORDERED_SAME;

	if (show_to_int(show) < show_to_int(otherShow))
		return OF_ORDERED_ASCENDING;

	return OF_ORDERED_DESCENDING;
}
@end
