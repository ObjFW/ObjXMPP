/*
 * Copyright (c) 2013, Florian Zeitz <florob@babelmonkeys.de>
 * Copyright (c) 2013, 2016, Jonathan Schleifer <js@heap.zone>
 *
 * https://heap.zone/git/?p=objxmpp.git
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

#import <ObjFW/ObjFW.h>

@class XMPPConnection;
@class XMPPJID;
@class XMPPRosterItem;
@class XMPPMessage;
@class XMPPPresence;

/**
 * \brief A class describing a contact tracked by a XMPPContactManager
 */
@interface XMPPContact: OFObject
{
	XMPPRosterItem *_rosterItem;
	OFMutableDictionary *_presences;
	XMPPJID *_lockedOnJID;
}

/// \brief The XMPPRosterItem corresponding to this contact
@property (readonly) XMPPRosterItem *rosterItem;
/// \brief The XMPPPresences of this contact with the resources as keys
@property (readonly) OFDictionary *presences;

/**
 * \brief Sends a message to the contact honoring resource locking
 *
 * \param message The message to send
 * \param connection The connection to use for sending the message
 */
- (void)sendMessage: (XMPPMessage*)message
	 connection: (XMPPConnection*)connection;

- (void)XMPP_setRosterItem: (XMPPRosterItem*)rosterItem;
- (void)XMPP_setPresence: (XMPPPresence*)presence
		resource: (OFString*)resource;
- (void)XMPP_removePresenceForResource: (OFString*)resource;
- (void)XMPP_setLockedOnJID: (XMPPJID*)JID;
@end
