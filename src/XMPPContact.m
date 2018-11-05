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

#import "XMPPContact.h"
#import "XMPPContact+Private.h"
#import "XMPPConnection.h"
#import "XMPPJID.h"
#import "XMPPMessage.h"
#import "XMPPRosterItem.h"

@implementation XMPPContact
@synthesize rosterItem = _rosterItem;
@synthesize presences = _presences;

- (instancetype)init
{
	self = [super init];

	@try {
		_presences = [[OFMutableDictionary alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_presences release];

	[super dealloc];
}

- (void)sendMessage: (XMPPMessage *)message
	 connection: (XMPPConnection *)connection
{
	if (_lockedOnJID == nil)
		[message setTo: [_rosterItem JID]];
	else
		[message setTo: _lockedOnJID];

	[connection sendStanza: message];
}

- (void)xmpp_setRosterItem: (XMPPRosterItem *)rosterItem
{
	XMPPRosterItem *old = _rosterItem;
	_rosterItem = [rosterItem retain];
	[old release];
}

- (void)xmpp_setPresence: (XMPPPresence *)presence
		resource: (OFString *)resource
{
	if (resource != nil)
		[_presences setObject: presence
			       forKey: resource];
	else
		[_presences setObject: presence
			       forKey: @""];

	[self xmpp_setLockedOnJID: nil];
}

- (void)xmpp_removePresenceForResource: (OFString *)resource
{
	if (resource != nil) {
		[_presences removeObjectForKey: resource];
	} else {
		[_presences release];
		_presences = [[OFMutableDictionary alloc] init];
	}

	[self xmpp_setLockedOnJID: nil];
}

- (void)xmpp_setLockedOnJID: (XMPPJID *)JID;
{
	XMPPJID *old = _lockedOnJID;
	_lockedOnJID = [JID retain];
	[old release];
}
@end
