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

#import <ObjFW/ObjFW.h>

#import "XMPPConnection.h"
#import "XMPPDiscoNode.h"

@class XMPPJID;

/**
 * \brief A class representing an entity responding to Service Discovery
 *	  queries
 */
@interface XMPPDiscoEntity: XMPPDiscoNode <XMPPConnectionDelegate>
{
	OFMutableDictionary *_discoNodes;
	XMPPConnection *_connection;
	OFString *_capsNode;
}

#ifdef OF_HAVE_PROPERTIES
/**
 * \brief The XMPPDiscoNodes this entity provides Services Discovery
 *	  responses for
 *
 * This usually contains at least all immediate child nodes, but may contain
 * any number of nodes nested more deeply.
 */
@property (readonly) OFDictionary *discoNodes;
/// \brief The node advertised for the entity's capabilites
@property (readonly) OFString *capsNode;
#endif

/**
 * \brief Creates a new autoreleased XMPPDiscoEntity with the specified
 *	  connection.
 *
 * \param connection The XMPPConnection to serve responses on.
 *	  This must already be bound to a resource)
 * \return A new autoreleased XMPPDiscoEntity
 */
+ discoEntityWithConnection: (XMPPConnection*)connection;

/**
 * \brief Creates a new autoreleased XMPPDiscoEntity with the specified
 *	  connection.
 *
 * \param connection The XMPPConnection to serve responses on.
 *	  This must already be bound to a resource)
 * \param capsNode The node advertised for the entity's capabilites
 * \return A new autoreleased XMPPDiscoEntity
 */
+ discoEntityWithConnection: (XMPPConnection*)connection
		   capsNode: (OFString*)capsNode;

/**
 * \brief Initializes an already allocated XMPPDiscoEntity with the specified
 *	  connection.
 *
 * \param connection The XMPPConnection to serve responses on.
 *	  This must already be bound to a resource)
 * \return An initialized XMPPDiscoEntity
 */
- initWithConnection: (XMPPConnection*)connection;

/**
 * \brief Initializes an already allocated XMPPDiscoEntity with the specified
 *	  connection.
 *
 * \param connection The XMPPConnection to serve responses on.
 *	  This must already be bound to a resource)
 * \param capsNode The node advertised for the entity's capabilites
 * \return An initialized XMPPDiscoEntity
 */
- initWithConnection: (XMPPConnection*)connection
	    capsNode: (OFString*)capsNode;

/**
 * \brief Adds a XMPPDiscoNode to provide responses for.
 *
 * \param node The XMPPDiscoNode to provide responses for
 */
- (void)addDiscoNode: (XMPPDiscoNode*)node;

/**
 * \brief Calculates the Entity Capabilities Hash of the entity
 *
 * \return A OFString containing the capabilities hash
 */
- (OFString*)capsHash;

- (OFDictionary*)discoNodes;
- (OFString*)capsNode;
@end
