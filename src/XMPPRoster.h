/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2012, Florian Zeitz <florob@babelmonkeys.de>
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

#import <ObjFW/ObjFW.h>

#import "XMPPConnection.h"

@class XMPPRosterItem;
@class XMPPIQ;
@class XMPPRoster;
@class XMPPMulticastDelegate;

/**
 * \brief A protocol that should be (partially) implemented by delegates
 * 	  of a XMPPRoster
 */
@protocol XMPPRosterDelegate
#ifndef XMPP_ROSTER_M
    <OFObject>
#endif
#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif
/**
 * This callback is called after the roster was received (as a result of
 * calling -requestRoster.
 *
 * \param roster The roster that was received
 */
- (void)rosterWasReceived: (XMPPRoster*)roster;

/**
 * This callback is called whenever a roster push was received.
 *
 * \param roster The roster that was updated by the roster push
 * \param rosterItem The roster item received in the push
 */
-         (void)roster: (XMPPRoster*)roster
  didReceiveRosterItem: (XMPPRosterItem*)rosterItem;
@end

/**
 * \brief A class implementing roster related functionality
 */
@interface XMPPRoster: OFObject
#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
    <XMPPConnectionDelegate>
#endif
{
	XMPPConnection *connection;
	OFMutableDictionary *rosterItems;
	XMPPMulticastDelegate *delegates;
}

/**
 * Initializes an already allocated XMPPRoster
 *
 * \param connection The connection roster related stanzas
 *	  are send and received over
 * \return An initialized XMPPRoster
 */
- initWithConnection: (XMPPConnection*)connection;

/**
 * Returns the list of contacts as a OFDictionary with the bare JID as key
 *
 * \return An autoreleased copy of the dictionary containing the roster items
 */
- (OFDictionary*)rosterItems;

/**
 * Requests the roster from the server
 */
- (void)requestRoster;

/**
 * Adds a new contact to the roster
 *
 * \param rosterItem The roster item to add to the roster
 */
- (void)addRosterItem: (XMPPRosterItem*)rosterItem;

/**
 * Updates an already existing contact in the roster
 *
 * \param rosterItem The roster item to update
 */
- (void)updateRosterItem: (XMPPRosterItem*)rosterItem;

/**
 * Delete a contact from the roster
 *
 * \param rosterItem The roster item to delete
 */
- (void)deleteRosterItem: (XMPPRosterItem*)rosterItem;

/**
 * Adds the specified delegate
 *
 * \param delegate The delegate to add
 */
- (void)addDelegate: (id <XMPPRosterDelegate>)delegate;

/**
 * Removes the specified delegate
 *
 * \param delegate The delegate to remove
 */
- (void)removeDelegate: (id <XMPPRosterDelegate>)delegate;

- (void)XMPP_addRosterItem: (XMPPRosterItem*)rosterItem;
- (void)XMPP_updateRosterItem: (XMPPRosterItem*)rosterItem;
- (void)XMPP_deleteRosterItem: (XMPPRosterItem*)rosterItem;
- (void)XMPP_handleInitialRoster: (XMPPIQ*)iq;
- (XMPPRosterItem*)XMPP_rosterItemWithXMLElement: (OFXMLElement*)element;
@end

@interface OFObject (XMPPRosterDelegate) <XMPPRosterDelegate>
@end
