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

#import <ObjFW/ObjFW.h>

OF_ASSUME_NONNULL_BEGIN

@class XMPPJID;

/*!
 * @brief A class for representing an item in the roster.
 */
@interface XMPPRosterItem: OFObject
{
	XMPPJID *_JID;
	OFString *_name;
	OFString *_subscription;
	OFArray *_groups;
}

/*!
 * The JID of the roster item.
 */
@property (nonatomic, copy) XMPPJID *JID;

/*!
 * The name of the roster item to show to the user.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *name;

/*!
 * The subscription for the roster item.
 */
@property (nonatomic, copy) OFString *subscription;

/*!
 * An array of groups in which the roster item is.
 */
@property (nonatomic, copy) OFArray OF_GENERIC(OFString *) *groups;

/*!
 * @brief Creates a new autoreleased roster item.
 *
 * @return A new autoreleased roster item.
 */
+ (instancetype)rosterItem;
@end

OF_ASSUME_NONNULL_END
