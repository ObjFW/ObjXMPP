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

#import <ObjFW/ObjFW.h>

#import "XMPPConnection.h"
#import "XMPPRoster.h"

OF_ASSUME_NONNULL_BEGIN

@class XMPPContact;
@class XMPPContactManager;
@class XMPPMulticastDelegate;
@class XMPPPresence;

/**
 * \brief A protocol that should be (partially) implemented by delegates
 *	  of a XMPPContactManager
 */
@protocol XMPPContactManagerDelegate <OFObject>
@optional
/**
 * \brief This callback is called whenever a new contact enters the users roster
 *
 * \param manager The contact manager that added the contact
 * \param contact The contact that was added
 */
- (void)contactManager: (XMPPContactManager *)manager
	 didAddContact: (XMPPContact *)contact;

/**
 * \brief This callback is called whenever a contact is no longer present in
 *	  the users roster
 *
 * \param manager The contact manager that removed the contact
 * \param contact The contact that was removed
 */
- (void)contactManager: (XMPPContactManager *)manager
      didRemoveContact: (XMPPContact *)contact;

/**
 * \brief This callback is called when a subscription request is received
 *
 * \param manager The contact manager that received the request
 * \param presence The type=subscribe presence
 */
-          (void)contactManager: (XMPPContactManager *)manager
  didReceiveSubscriptionRequest: (XMPPPresence *)presence;

/**
 * \brief This callback is called whenever a contact is about to change its
 *	  roster item
 *
 * \param contact The contact about to updated its roster item
 * \param rosterItem The roster item the contact is going to update with
 */
-	     (void)contact: (XMPPContact *)contact
  willUpdateWithRosterItem: (XMPPRosterItem *)rosterItem;

/**
 * \brief This callback is called whenever a contact send a presence stanza
 *
 * \param contact The contact that send the presence
 * \param presence The presence which was send by the contact
 */
-   (void)contact: (XMPPContact *)contact
  didSendPresence: (XMPPPresence *)presence;

/**
 * \brief This callback is called whenever a contact send a message stanza
 *
 * \param contact The contact that send the message
 * \param message The message which was send by the contact
 */
-  (void)contact: (XMPPContact *)contact
  didSendMessage: (XMPPMessage *)message;
@end

/**
 * \brief A class tracking a XMPPContact instance for each contact in the roster
 *
 * This class delegates to a XMPPConnection and a XMPPRoster, thereby tracking
 * each contacts presences and the current XMPPRosterItem.
 */
@interface XMPPContactManager: OFObject <XMPPConnectionDelegate,
    XMPPRosterDelegate>
{
	OFMutableDictionary *_contacts;
	XMPPConnection *_connection;
	XMPPRoster *_roster;
	XMPPMulticastDelegate *_delegates;
}

/// \brief The tracked contacts, with their bare JID as key
@property (readonly, nonatomic)
    OFDictionary OF_GENERIC(OFString *, XMPPContact *) *contacts;

/*!
 * @brief Initializes an already allocated XMPPContactManager.
 *
 * @param connection The connection to be used to track contacts
 * @param roster The roster used by the contact manager
 * @return An initialized XMPPContactManager
 */
- initWithConnection: (XMPPConnection *)connection
	      roster: (XMPPRoster *)roster OF_DESIGNATED_INITIALIZER;

- (void)sendSubscribedToJID: (XMPPJID *)subscriber;
- (void)sendUnsubscribedToJID: (XMPPJID *)subscriber;

/**
 * \brief Adds the specified delegate.
 *
 * \param delegate The delegate to add
 */
- (void)addDelegate: (id <XMPPContactManagerDelegate>)delegate;

/**
 * \brief Removes the specified delegate.
 *
 * \param delegate The delegate to remove
 */
- (void)removeDelegate: (id <XMPPContactManagerDelegate>)delegate;
@end

OF_ASSUME_NONNULL_END
