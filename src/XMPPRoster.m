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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <assert.h>

#import "XMPPRoster.h"
#import "XMPPRosterItem.h"
#import "XMPPConnection.h"
#import "XMPPIQ.h"
#import "XMPPJID.h"
#import "namespaces.h"

@implementation XMPPRoster
- initWithConnection: (XMPPConnection*)conn
{
	self = [super init];

	@try {
		connection = [conn retain];
		rosterItems = [[OFMutableDictionary alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[connection release];
	[rosterItems release];
	[rosterID release];

	[super dealloc];
}

- (void)XMPP_addRosterItem: (XMPPRosterItem*)rosterItem
{
	return [self XMPP_updateRosterItem: rosterItem];
}

- (void)XMPP_updateRosterItem: (XMPPRosterItem*)rosterItem
{
	[rosterItems setObject: rosterItem
			forKey: [[rosterItem JID] bareJID]];
}

- (void)XMPP_deleteRosterItem: (XMPPRosterItem*)rosterItem
{
	[rosterItems removeObjectForKey: [[rosterItem JID] bareJID]];
}

- (OFDictionary*)rosterItems
{
	return [[rosterItems copy] autorelease];
}

- (void)requestRoster
{
	XMPPIQ *iq;

	if (rosterID != nil)
		assert(0);

	rosterID = [[connection generateStanzaID] retain];
	iq = [XMPPIQ IQWithType: @"get"
			     ID: rosterID];
	[iq addChild: [OFXMLElement elementWithName: @"query"
					  namespace: XMPP_NS_ROSTER]];
	[connection sendStanza: iq];
}

- (BOOL)handleIQ: (XMPPIQ*)iq
{
	OFXMLElement *rosterElement;
	OFXMLElement *element;
	XMPPRosterItem *rosterItem = nil;
	OFString *subscription;
	OFEnumerator *enumerator;
	BOOL isPush = ![[iq ID] isEqual: rosterID];

	rosterElement = [iq elementForName: @"query"
				 namespace: XMPP_NS_ROSTER];

	if (rosterElement == nil)
		return NO;

	if (isPush) {
		if (![[iq type] isEqual: @"set"])
			return NO;
	} else {
		if (![[iq type] isEqual: @"result"])
			return NO;
	}

	enumerator = [[rosterElement children] objectEnumerator];
	while ((element = [enumerator nextObject]) != nil) {
		OFMutableArray *groups = [OFMutableArray array];
		OFEnumerator *groupEnumerator;
		OFXMLElement *groupElement;

		if (![[element name] isEqual: @"item"] ||
		    ![[element namespace] isEqual: XMPP_NS_ROSTER])
			continue;

		rosterItem = [XMPPRosterItem rosterItem];
		[rosterItem setJID: [XMPPJID JIDWithString:
		    [[element attributeForName: @"jid"] stringValue]]];
		[rosterItem setName:
		    [[element attributeForName: @"name"] stringValue]];

		subscription = [[element attributeForName:
		    @"subscription"] stringValue];

		if (![subscription isEqual: @"none"] &&
		    ![subscription isEqual: @"to"] &&
		    ![subscription isEqual: @"from"] &&
		    ![subscription isEqual: @"both"] &&
		    (![subscription isEqual: @"remove"] || !isPush))
			subscription = @"none";

		[rosterItem setSubscription: subscription];

		groupEnumerator = [[element
		    elementsForName: @"group"
			  namespace: XMPP_NS_ROSTER] objectEnumerator];
		while ((groupElement = [groupEnumerator nextObject]) != nil)
			[groups addObject: [groupElement stringValue]];

		if ([groups count] > 0)
			[rosterItem setGroups: groups];

		if ([subscription isEqual: @"remove"])
			[self XMPP_deleteRosterItem: rosterItem];
		else
			[self XMPP_addRosterItem: rosterItem];

		if (isPush && [[connection delegate] respondsToSelector:
		    @selector(connection:didReceiveRosterItem:)])
			[[connection delegate] connection: connection
				     didReceiveRosterItem: rosterItem];
	}

	if (isPush) {
		[connection sendStanza: [iq resultIQ]];
	} else {
		if ([[connection delegate] respondsToSelector:
		     @selector(connectionDidReceiveRoster:)])
			[[connection delegate]
			    connectionDidReceiveRoster: connection];

		[rosterID release];
		rosterID = nil;
	}

	return YES;
}

- (void)addRosterItem: (XMPPRosterItem*)rosterItem
{
	[self updateRosterItem: rosterItem];
}

- (void)updateRosterItem: (XMPPRosterItem*)rosterItem
{
	XMPPIQ *iq = [XMPPIQ IQWithType: @"set"
				     ID: [connection generateStanzaID]];
	OFXMLElement *query = [OFXMLElement elementWithName: @"query"
						  namespace: XMPP_NS_ROSTER];
	OFXMLElement *item = [OFXMLElement elementWithName: @"item"
						 namespace: XMPP_NS_ROSTER];
	OFEnumerator *enumerator;
	OFString *group;

	[item addAttributeWithName: @"jid"
		       stringValue: [[rosterItem JID] bareJID]];
	if ([rosterItem name] != nil)
		[item addAttributeWithName: @"name"
			       stringValue: [rosterItem name]];

	enumerator = [[rosterItem groups] objectEnumerator];
	while ((group = [enumerator nextObject]) != nil)
		[item addChild: [OFXMLElement elementWithName: @"group"
						    namespace: XMPP_NS_ROSTER
						  stringValue: group]];

	[query addChild: item];
	[iq addChild: query];

	[connection sendStanza: iq];
}

- (void)deleteRosterItem: (XMPPRosterItem*)rosterItem
{
	XMPPIQ *iq = [XMPPIQ IQWithType: @"set"
				     ID: [connection generateStanzaID]];
	OFXMLElement *query = [OFXMLElement elementWithName: @"query"
						  namespace: XMPP_NS_ROSTER];
	OFXMLElement *item = [OFXMLElement elementWithName: @"item"
						 namespace: XMPP_NS_ROSTER];

	[item addAttributeWithName: @"jid"
		       stringValue: [[rosterItem JID] bareJID]];
	[item addAttributeWithName: @"subscription"
		       stringValue: @"remove"];

	[query addChild: item];
	[iq addChild: query];

	[connection sendStanza: iq];
}
@end
