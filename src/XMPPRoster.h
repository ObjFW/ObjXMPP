/*
 * Copyright (c) 2011, 2012, 2013, 2016, Jonathan Schleifer <js@nil.im>
 * Copyright (c) 2012, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://nil.im/objxmpp/
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
#import "XMPPStorage.h"

OF_ASSUME_NONNULL_BEGIN

@class XMPPRosterItem;
@class XMPPIQ;
@class XMPPRoster;
@class XMPPMulticastDelegate;

/*!
 * @brief A protocol that should be (partially) implemented by delegates
 *	  of a XMPPRoster
 */
@protocol XMPPRosterDelegate
@optional
/*!
 * @brief This callback is called after the roster was received (as a result of
 *	  calling -requestRoster).
 *
 * @param roster The roster that was received
 */
- (void)rosterWasReceived: (XMPPRoster *)roster;

/*!
 * @brief This callback is called whenever a roster push was received.
 *
 * @param roster The roster that was updated by the roster push
 * @param rosterItem The roster item received in the push
 */
-         (void)roster: (XMPPRoster *)roster
  didReceiveRosterItem: (XMPPRosterItem *)rosterItem;
@end

/*!
 * @brief A class implementing roster related functionality.
 */
@interface XMPPRoster: OFObject <XMPPConnectionDelegate>
{
	XMPPConnection *_connection;
	OFMutableDictionary *_rosterItems;
	XMPPMulticastDelegate *_delegates;
	id <XMPPStorage> _dataStorage;
	bool _rosterRequested;
}

/*!
 * @brief The connection to which the roster belongs
 */
@property (readonly, nonatomic) XMPPConnection *connection;

/*!
 * @brief An object for data storage, conforming to the XMPPStorage protocol.
 *
 * Inherited from the connection if not overridden.
 */
@property (nonatomic, assign) id <XMPPStorage> dataStorage;

/*!
 * @brief The list of contacts as an OFDictionary with the bare JID as a string
 *	  as key.
 */
@property (readonly, nonatomic)
    OFDictionary OF_GENERIC(OFString *, XMPPRosterItem *) *rosterItems;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated XMPPRoster.
 *
 * @param connection The connection roster related stanzas are send and
 *		     received over
 * @return An initialized XMPPRoster
 */
- (instancetype)initWithConnection: (XMPPConnection *)connection
    OF_DESIGNATED_INITIALIZER;

/*!
 * @brief Requests the roster from the server.
 */
- (void)requestRoster;

/*!
 * @brief Adds a new contact to the roster.
 *
 * @param rosterItem The roster item to add to the roster
 */
- (void)addRosterItem: (XMPPRosterItem *)rosterItem;

/*!
 * @brief Updates an already existing contact in the roster.
 *
 * @param rosterItem The roster item to update
 */
- (void)updateRosterItem: (XMPPRosterItem *)rosterItem;

/*!
 * @brief Delete a contact from the roster.
 *
 * @param rosterItem The roster item to delete
 */
- (void)deleteRosterItem: (XMPPRosterItem *)rosterItem;

/*!
 * @brief Adds the specified delegate.
 *
 * @param delegate The delegate to add
 */
- (void)addDelegate: (id <XMPPRosterDelegate>)delegate;

/*!
 * @brief Removes the specified delegate.
 *
 * @param delegate The delegate to remove
 */
- (void)removeDelegate: (id <XMPPRosterDelegate>)delegate;
@end

OF_ASSUME_NONNULL_END
