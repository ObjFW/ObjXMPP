/*
 * Copyright (c) 2011, 2012, 2013, 2016, Jonathan Schleifer <js@heap.zone>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
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
 * @brief A class describing an XMPP Stanza.
 */
@interface XMPPStanza: OFXMLElement
{
	XMPPJID *_from, *_to;
	OFString *_type, *_ID, *_language;
}

/*!
 * The value of the stanza's from attribute.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) XMPPJID *from;

/*!
 * The value of the stanza's to attribute.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) XMPPJID *to;

/*!
 * The value of the stanza's type attribute.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *type;

/*!
 * The value of the stanza's id attribute.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *ID;

/*!
 * The stanza's xml:lang.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *language;

/*!
 * @brief Creates a new autoreleased XMPPStanza with the specified name.
 *
 * @param name The stanza's name (one of iq, message or presence)
 * @return A new autoreleased XMPPStanza
 */
+ (instancetype)stanzaWithName: (OFString *)name;

/*!
 * @brief Creates a new autoreleased XMPPStanza with the specified name and
 *	  type.
 *
 * @param name The stanza's name (one of iq, message or presence)
 * @param type The value for the stanza's type attribute
 * @return A new autoreleased XMPPStanza
 */
+ (instancetype)stanzaWithName: (OFString *)name
			  type: (nullable OFString *)type;

/*!
 * @brief Creates a new autoreleased XMPPStanza with the specified name and ID.
 *
 * @param name The stanza's name (one of iq, message or presence)
 * @param ID The value for the stanza's id attribute
 * @return A new autoreleased XMPPStanza
 */
+ (instancetype)stanzaWithName: (OFString *)name
			    ID: (nullable OFString *)ID;

/*!
 * @brief Creates a new autoreleased XMPPStanza with the specified name, type
 *	  and ID.
 *
 * @param name The stanza's name (one of iq, message or presence)
 * @param type The value for the stanza's type attribute
 * @param ID The value for the stanza's id attribute
 * @return A new autoreleased XMPPStanza
 */
+ (instancetype)stanzaWithName: (OFString *)name
			  type: (nullable OFString *)type
			    ID: (nullable OFString *)ID;

/*!
 * @brief Creates a new autoreleased XMPPStanza from an OFXMLElement.
 *
 * @param element The element to base the XMPPStanza on
 * @return A new autoreleased XMPPStanza
 */
+ (instancetype)stanzaWithElement: (OFXMLElement *)element;

- (instancetype)initWithName: (OFString *)name
		 stringValue: (nullable OFString *)stringValue OF_UNAVAILABLE;
- (instancetype)initWithName: (OFString *)name
		   namespace: (nullable OFString *)namespace OF_UNAVAILABLE;
- (instancetype)initWithName: (OFString *)name
		   namespace: (nullable OFString *)namespace
		 stringValue: (nullable OFString *)stringValue OF_UNAVAILABLE;
- (instancetype)initWithXMLString: (OFString *)string OF_UNAVAILABLE;
- (instancetype)initWithFile: (OFString *)path OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated XMPPStanza with the specified name.
 *
 * @param name The stanza's name (one of iq, message or presence)
 * @return A initialized XMPPStanza
 */
- (instancetype)initWithName: (OFString *)name;

/*!
 * @brief Initializes an already allocated XMPPStanza with the specified name
 *	  and type.
 *
 * @param name The stanza's name (one of iq, message or presence)
 * @param type The value for the stanza's type attribute
 * @return A initialized XMPPStanza
 */
- (instancetype)initWithName: (OFString *)name
			type: (nullable OFString *)type;

/*!
 * @brief Initializes an already allocated XMPPStanza with the specified name
 *	  and ID.
 *
 * @param name The stanza's name (one of iq, message or presence)
 * @param ID The value for the stanza's id attribute
 * @return A initialized XMPPStanza
 */
- (instancetype)initWithName: (OFString *)name
			  ID: (nullable OFString *)ID;

/*!
 * @brief Initializes an already allocated XMPPStanza with the specified name,
 *	  type and ID.
 *
 * @param name The stanza's name (one of iq, message or presence)
 * @param type The value for the stanza's type attribute
 * @param ID The value for the stanza's id attribute
 * @return A initialized XMPPStanza
 */
- (instancetype)initWithName: (OFString *)name
			type: (nullable OFString *)type
			  ID: (nullable OFString *)ID;

/*!
 * @brief Initializes an already allocated XMPPStanza based on a OFXMLElement.
 *
 * @param element The element to base the XMPPStanza on
 * @return A initialized XMPPStanza
 */
- (instancetype)initWithElement: (OFXMLElement *)element;
@end

OF_ASSUME_NONNULL_END
