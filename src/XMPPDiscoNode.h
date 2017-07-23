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

OF_ASSUME_NONNULL_BEGIN

@class XMPPDiscoIdentity;
@class XMPPJID;

/*!
 * @brief A class describing a Service Discovery Node
 */
@interface XMPPDiscoNode: OFObject
{
	XMPPJID *_JID;
	OFString *_node;
	OFString *_name;
	OFSortedList *_identities;
	OFSortedList *_features;
	OFMutableDictionary *_childNodes;
}

/*!
 * @brief The JID this node lives on.
 */
@property (readonly, nonatomic) XMPPJID *JID;

/*!
 * @brief The node's opaque name of the node.
 */
@property (readonly, nonatomic) OFString *node;

/*!
 * @brief The node's human friendly name (may be unspecified).
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *name;

/*!
 * @brief The node's list of identities.
 */
@property (readonly, nonatomic) OFSortedList *identities;

/*!
 * @brief The node's list of features.
 */
@property (readonly, nonatomic) OFSortedList *features;

/*!
 * @brief The node's children.
 */
@property (readonly, nonatomic) OFDictionary *childNodes;

/*!
 * @brief Creates a new autoreleased XMPPDiscoNode with the specified
 *	  JID and node
 *
 * @param JID The JID this node lives on
 * @param node The node's opaque name
 * @return A new autoreleased XMPPDiscoNode
 */
+ (instancetype)discoNodeWithJID: (XMPPJID *)JID
			    node: (nullable OFString *)node;

/*!
 * @brief Creates a new autoreleased XMPPDiscoNode with the specified
 *	  JID, node and name
 *
 * @param JID The JID this node lives on
 * @param node The node's opaque name
 * @param name The node's human friendly name
 * @return A new autoreleased XMPPDiscoNode
 */
+ (instancetype)discoNodeWithJID: (XMPPJID *)JID
			    node: (nullable OFString *)node
			    name: (nullable OFString *)name;

/*!
 * @brief Initializes an already allocated XMPPDiscoNode with the specified
 *	  JID and node
 *
 * @param JID The JID this node lives on
 * @param node The node's opaque name
 * @return An initialized XMPPDiscoNode
 */
- initWithJID: (XMPPJID *)JID
	 node: (nullable OFString *)node;

/*!
 * @brief Initializes an already allocated XMPPDiscoNode with the specified
 *	  JID, node and name
 *
 * @param JID The JID this node lives on
 * @param node The node's opaque name
 * @param name The node's human friendly name
 * @return An initialized XMPPDiscoNode
 */
- initWithJID: (XMPPJID *)JID
	 node: (nullable OFString *)node
	 name: (nullable OFString *)name OF_DESIGNATED_INITIALIZER;

 /*!
  * @brief Adds an XMPPDiscoIdentity to the node
  *
  * @param identity The XMPPDiscoIdentity to add
  */
- (void)addIdentity: (XMPPDiscoIdentity *)identity;

 /*!
  * @brief Adds a feature to the node
  *
  * @param feature The feature to add
  */
- (void)addFeature: (OFString *)feature;

 /*!
  * @brief Adds a XMPPDiscoNode as child of the node
  *
  * @param node The XMPPDiscoNode to add as child
  */
- (void)addChildNode: (XMPPDiscoNode *)node;
@end

OF_ASSUME_NONNULL_END
