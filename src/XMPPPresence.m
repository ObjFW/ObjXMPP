/*
 * Copyright (c) 2011, 2012, 2013, 2016, 2019, 2021,
 *   Jonathan Schleifer <js@nil.im>
 * Copyright (c) 2011, 2012, 2013, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://nil.im/objxmpp/
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

#include "config.h"

#include <inttypes.h>

#import "XMPPPresence.h"
#import "namespaces.h"

/* This provides us with sortable values for show values */
static int
showToInt(OFString *show)
{
	if ([show isEqual: @"chat"])
		return 0;
	if (show == nil)
		return 1;	/* available */
	if ([show isEqual: @"away"])
		return 2;
	if ([show isEqual: @"dnd"])
		return 3;
	if ([show isEqual: @"xa"])
		return 4;

	OFEnsure(0);
}

@implementation XMPPPresence
@synthesize status = _status, show = _show, priority = _priority;

+ (instancetype)presence
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)presenceWithID: (OFString *)ID
{
	return [[[self alloc] initWithID: ID] autorelease];
}

+ (instancetype)presenceWithType: (OFString *)type
{
	return [[[self alloc] initWithType: type] autorelease];
}

+ (instancetype)presenceWithType: (OFString *)type ID: (OFString *)ID
{
	return [[[self alloc] initWithType: type ID: ID] autorelease];
}

- (instancetype)init
{
	return [self initWithType: nil ID: nil];
}

- (instancetype)initWithID: (OFString *)ID
{
	return [self initWithType: nil ID: ID];
}

- (instancetype)initWithType: (OFString *)type
{
	return [self initWithType: type ID: nil];
}

- (instancetype)initWithType: (OFString *)type ID: (OFString *)ID
{
	return [super initWithName: @"presence" type: type ID: ID];
}

- (instancetype)initWithElement: (OFXMLElement *)element
{
	self = [super initWithElement: element];

	@try {
		OFXMLElement *subElement;

		if ((subElement = [element elementForName: @"show"
						namespace: XMPPClientNS]))
			self.show = subElement.stringValue;

		if ((subElement = [element elementForName: @"status"
						namespace: XMPPClientNS]))
			self.status = subElement.stringValue;

		if ((subElement = [element elementForName: @"priority"
						namespace: XMPPClientNS]))
			self.priority = [OFNumber numberWithLongLong:
			    [subElement longLongValueWithBase: 10]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_status release];
	[_show release];
	[_priority release];

	[super dealloc];
}

- (void)setShow: (OFString *)show
{
	OFXMLElement *oldShow = [self elementForName: @"show"
					   namespace: XMPPClientNS];
	OFString *old;

	if (oldShow != nil)
		[self removeChild: oldShow];

	if (show != nil)
		[self addChild: [OFXMLElement elementWithName: @"show"
						    namespace: XMPPClientNS
						  stringValue: show]];

	old = _show;
	_show = [show copy];
	[old release];
}

- (void)setStatus: (OFString *)status
{
	OFXMLElement *oldStatus = [self elementForName: @"status"
					     namespace: XMPPClientNS];
	OFString *old;

	if (oldStatus != nil)
		[self removeChild: oldStatus];

	if (status != nil)
		[self addChild: [OFXMLElement elementWithName: @"status"
						    namespace: XMPPClientNS
						  stringValue: status]];

	old = _status;
	_status = [status copy];
	[old release];
}

- (void)setPriority: (OFNumber *)priority
{
	long long prio = priority.longLongValue;
	OFNumber *old;

	if ((prio < -128) || (prio > 127))
		@throw [OFInvalidArgumentException exception];

	OFXMLElement *oldPriority = [self elementForName: @"priority"
					       namespace: XMPPClientNS];

	if (oldPriority != nil)
		[self removeChild: oldPriority];

	OFString *priority_s =
	    [OFString stringWithFormat: @"%hhd", priority.charValue];
	[self addChild: [OFXMLElement elementWithName: @"priority"
					    namespace: XMPPClientNS
					  stringValue: priority_s]];

	old = _priority;
	_priority = [priority copy];
	[old release];
}

- (OFComparisonResult)compare: (id <OFComparing>)object
{
	XMPPPresence *otherPresence;
	OFNumber *otherPriority;
	OFString *otherShow;
	OFComparisonResult priorityOrder;

	if (object == self)
		return OFOrderedSame;

	if (![(id)object isKindOfClass: [XMPPPresence class]])
		@throw [OFInvalidArgumentException exception];

	otherPresence = (XMPPPresence *)object;
	otherPriority = otherPresence.priority;
	if (otherPriority == nil)
		otherPriority = [OFNumber numberWithChar: 0];

	if (_priority != nil)
		priorityOrder = [_priority compare: otherPriority];
	else
		priorityOrder =
		    [[OFNumber numberWithChar: 0] compare: otherPriority];

	if (priorityOrder != OFOrderedSame)
		return priorityOrder;

	otherShow = otherPresence.show;
	if ([_show isEqual: otherShow])
		return OFOrderedSame;

	if (showToInt(_show) < showToInt(otherShow))
		return OFOrderedAscending;

	return OFOrderedDescending;
}
@end
