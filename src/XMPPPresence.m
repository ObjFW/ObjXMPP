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

#import "XMPPPresence.h"
#import "namespaces.h"

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

- (OFString*)type
{
	if (type == nil)
		return @"available";

	return [[type copy] autorelease];
}

- (void)addShow: (OFString*)show
{
	[self addChild: [OFXMLElement elementWithName: @"show"
					    namespace: XMPP_NS_CLIENT
					  stringValue: show]];
}

- (void)addStatus: (OFString*)status
{
	[self addChild: [OFXMLElement elementWithName: @"status"
					    namespace: XMPP_NS_CLIENT
					  stringValue: status]];
}

- (void)addPriority: (int8_t)priority
{
	OFString* prio = [OFString stringWithFormat: @"%" @PRId8, priority];
	[self addChild: [OFXMLElement elementWithName: @"priority"
					    namespace: XMPP_NS_CLIENT
					  stringValue: prio]];
}
@end
