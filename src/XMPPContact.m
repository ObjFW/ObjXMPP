/*
 * Copyright (c) 2013, Florian Zeitz <florob@babelmonkeys.de>
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

#import "XMPPContact.h"
#import "XMPPMessage.h"
#import "XMPPConnection.h"

@implementation XMPPContact
- init
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

- (XMPPRosterItem*)rosterItem
{
	OF_GETTER(_rosterItem, true)
}

- (OFDictionary*)presences
{
	OF_GETTER(_presences, true)
}

- (void)sendMessage: (XMPPMessage*)message
	 connection: (XMPPConnection*)connection
{
	if (_lockedOnJID == nil)
		[message setTo: [_rosterItem JID]];
	else
		[message setTo: _lockedOnJID];

	[connection sendStanza: message];
}

- (void)XMPP_setRosterItem: (XMPPRosterItem*)rosterItem
{
	OF_SETTER(_rosterItem, rosterItem, true, 0);
}

- (void)XMPP_setPresence: (XMPPPresence*)presence
		resource: (OFString*)resource
{
	if (resource != nil)
		[_presences setObject: presence
			       forKey: resource];
	else
		[_presences setObject: presence
			       forKey: @""];

	[self XMPP_setLockedOnJID: nil];
}

- (void)XMPP_removePresenceForResource: (OFString*)resource
{
	if (resource != nil) {
		[_presences removeObjectForKey: resource];
	} else {
		[_presences release];
		_presences = [[OFMutableDictionary alloc] init];
	}

	[self XMPP_setLockedOnJID: nil];
}

- (void)XMPP_setLockedOnJID: (XMPPJID*)JID;
{
	OF_SETTER(_lockedOnJID, JID, true, 0);
}
@end
