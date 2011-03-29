/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
 *
 * https://webkeks.org/hg/objxmpp/
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

#import "XMPPRosterItem.h"

@implementation XMPPRosterItem
+ rosterItem
{
	return [[[self alloc] init] autorelease];
}

- (void)dealloc
{
	[JID release];
	[name release];
	[subscription release];
	[groups release];

	[super dealloc];
}

- copy
{
	XMPPRosterItem *new = [[XMPPRosterItem alloc] init];

	@try {
		new->JID = [JID copy];
		new->name = [name copy];
		new->subscription = [subscription copy];
		new->groups = [groups copy];
	} @catch (id e) {
		[new release];
		@throw e;
	}

	return new;
}

- (OFString*)description
{
	return [OFString stringWithFormat: @"<XMPPRosterItem, JID=%@, name=%@, "
					   @"subscription=%@, groups=%@>",
					   JID, name, subscription, groups];
}

- (void)setJID: (XMPPJID*)JID_
{
	XMPPJID *old = JID;
	JID = [JID_ copy];
	[old release];
}

- (XMPPJID*)JID
{
	return [[JID copy] autorelease];
}

- (void)setName: (OFString*)name_
{
	OFString *old = name;
	name = [name_ copy];
	[old release];
}

- (OFString*)name
{
	return [[name copy] autorelease];
}

- (void)setSubscription: (OFString*)subscription_
{
	OFString *old = subscription;
	subscription = [subscription_ copy];
	[old release];
}

- (OFString*)subscription
{
	return [[subscription copy] autorelease];
}

- (void)setGroups: (OFArray*)groups_
{
	OFArray *old = groups;
	groups = [groups_ copy];
	[old release];
}

- (OFArray*)groups
{
	return [[groups copy] autorelease];
}
@end
