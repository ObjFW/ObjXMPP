/*
 * Copyright (c) 2011, 2012, 2013, 2016, Jonathan Schleifer <js@heap.zone>
 * Copyright (c) 2012, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://heap.zone/objxmpp/
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

#import "XMPPRosterItem.h"
#import "XMPPJID.h"

#import <ObjFW/macros.h>

@implementation XMPPRosterItem
@synthesize JID = _JID, name = _name, subscription = _subscription;
@synthesize groups = _groups;

+ (instancetype)rosterItem
{
	return [[[self alloc] init] autorelease];
}

- (void)dealloc
{
	[_JID release];
	[_name release];
	[_subscription release];
	[_groups release];

	[super dealloc];
}

- copy
{
	XMPPRosterItem *new = [[XMPPRosterItem alloc] init];

	@try {
		new->_JID = [_JID copy];
		new->_name = [_name copy];
		new->_subscription = [_subscription copy];
		new->_groups = [_groups copy];
	} @catch (id e) {
		[new release];
		@throw e;
	}

	return new;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<XMPPRosterItem, JID=%@, name=%@, "
					   @"subscription=%@, groups=%@>",
					   _JID, _name, _subscription, _groups];
}
@end
