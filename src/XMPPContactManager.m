/*
 * Copyright (c) 2013, Florian Zeitz <florob@babelmonkeys.de>
 * Copyright (c) 2013, 2016, Jonathan Schleifer <js@heap.zone>
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

#import "XMPPContactManager.h"
#import "XMPPContact.h"
#import "XMPPContact+Private.h"
#import "XMPPJID.h"
#import "XMPPMulticastDelegate.h"
#import "XMPPPresence.h"
#import "XMPPRosterItem.h"

@implementation XMPPContactManager
@synthesize contacts = _contacts;

- (instancetype)initWithConnection: (XMPPConnection *)connection
			    roster: (XMPPRoster *)roster
{
	self = [super init];

	@try {
		_connection = connection;
		[_connection addDelegate: self];
		_roster = roster;
		[_roster addDelegate: self];
		_contacts = [[OFMutableDictionary alloc] init];
		_delegates = [[XMPPMulticastDelegate alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_connection removeDelegate: self];
	[_roster removeDelegate: self];
	[_delegates release];
	[_contacts release];

	[super dealloc];
}


- (void)sendSubscribedToJID: (XMPPJID *)subscriber
{
	XMPPPresence *presence = [XMPPPresence presenceWithType: @"subscribed"];
	[presence setTo: subscriber];
	[_connection sendStanza: presence];
}

- (void)sendUnsubscribedToJID: (XMPPJID *)subscriber
{
	XMPPPresence *presence =
	    [XMPPPresence presenceWithType: @"unsubscribed"];
	[presence setTo: subscriber];
	[_connection sendStanza: presence];
}

- (void)addDelegate: (id <XMPPContactManagerDelegate>)delegate
{
	[_delegates addDelegate: delegate];
}

- (void)removeDelegate: (id <XMPPContactManagerDelegate>)delegate
{
	[_delegates removeDelegate: delegate];
}

- (void)rosterWasReceived: (XMPPRoster *)roster
{
	OFDictionary *rosterItems;

	for (XMPPContact *contact in _contacts)
		[_delegates broadcastSelector: @selector(contactManager:
						   didRemoveContact:)
				   withObject: self
				   withObject: contact];
	[_contacts release];
	_contacts = nil;

	_contacts = [[OFMutableDictionary alloc] init];

	rosterItems = [roster rosterItems];
	for (OFString *bareJID in rosterItems) {
		XMPPContact *contact = [[[XMPPContact alloc] init] autorelease];
		[contact xmpp_setRosterItem:
		    [rosterItems objectForKey: bareJID]];
		[_contacts setObject: contact
			      forKey: bareJID];
		[_delegates broadcastSelector: @selector(contactManager:
						   didAddContact:)
				   withObject: self
				   withObject: contact];
	}
}

-         (void)roster: (XMPPRoster *)roster
  didReceiveRosterItem: (XMPPRosterItem *)rosterItem
{
	XMPPContact *contact;
	OFString *bareJID = [[rosterItem JID] bareJID];

	contact = [_contacts objectForKey: bareJID];

	if ([[rosterItem subscription] isEqual: @"remove"]) {
		if (contact != nil)
			[_delegates broadcastSelector: @selector(contactManager:
							   didRemoveContact:)
					   withObject: self
					   withObject: contact];
		[_contacts removeObjectForKey: bareJID];
		return;
	}

	if (contact == nil) {
		contact = [[[XMPPContact alloc] init] autorelease];
		[contact xmpp_setRosterItem: rosterItem];
		[_contacts setObject: contact
			     forKey: bareJID];
		[_delegates broadcastSelector: @selector(contactManager:
						   didAddContact:)
				   withObject: self
				   withObject: contact];
	} else {
		[_delegates broadcastSelector: @selector(contact:
						   willUpdateWithRosterItem:)
				   withObject: contact
				   withObject: rosterItem];
		[contact xmpp_setRosterItem: rosterItem];
	}
}

-   (void)connection: (XMPPConnection *)connection
  didReceivePresence: (XMPPPresence *)presence
{
	XMPPContact *contact;
	XMPPJID *JID = [presence from];
	OFString *type = [presence type];

	/* Subscription request */
	if ([type isEqual: @"subscribe"]) {
		of_log(@"ObjXMPP: received subscription request");
		[_delegates broadcastSelector: @selector(contactManager:
						 didReceiveSubscriptionRequest:)
				   withObject: self
				   withObject: presence];
		return;
	}

	contact = [_contacts objectForKey: [JID bareJID]];
	if (contact == nil)
		return;

	/* Available presence */
	if ([type isEqual: @"available"]) {
		[contact xmpp_setPresence: presence
				 resource: [JID resource]];
		[_delegates broadcastSelector: @selector(contact:
						   didSendPresence:)
				   withObject: contact
				   withObject: presence];
		return;
	}

	/* Unavailable presence */
	if ([type isEqual: @"unavailable"]) {
		[contact xmpp_removePresenceForResource: [JID resource]];
		[_delegates broadcastSelector: @selector(contact:
						   didSendPresence:)
				   withObject: contact
				   withObject: presence];
		return;
	}
}

-  (void)connection: (XMPPConnection *)connection
  didReceiveMessage: (XMPPMessage *)message
{
	XMPPJID *JID = [message from];
	XMPPContact *contact = [_contacts objectForKey: [JID bareJID]];

	if (contact == nil)
		return;

	[contact xmpp_setLockedOnJID: JID];

	[_delegates broadcastSelector: @selector(contact:didSendMessage:)
			   withObject: contact
			   withObject: message];
}
@end
