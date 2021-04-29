/*
 * Copyright (c) 2011, 2012, 2013, 2016, Jonathan Schleifer <js@nil.im>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
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

#import "XMPPStanza.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @brief A class describing a message stanza.
 */
@interface XMPPMessage: XMPPStanza
/*!
 * The text content of the body of the message.
 */
@property (nonatomic, copy) OFString *body;

/*!
 * @brief Creates a new autoreleased XMPPMessage.
 *
 * @return A new autoreleased XMPPMessage
 */
+ (instancetype)message;

/*!
 * @brief Creates a new autoreleased XMPPMessage with the specified ID.
 *
 * @param ID The value for the stanza's id attribute
 * @return A new autoreleased XMPPMessage
 */
+ (instancetype)messageWithID: (nullable OFString *)ID;

/*!
 * @brief Creates a new autoreleased XMPPMessage with the specified type.
 *
 * @param type The value for the stanza's type attribute
 * @return A new autoreleased XMPPMessage
 */
+ (instancetype)messageWithType: (nullable OFString *)type;

/*!
 * @brief Creates a new autoreleased XMPPMessage with the specified type and ID.
 *
 * @param type The value for the stanza's type attribute
 * @param ID The value for the stanza's id attribute
 * @return A new autoreleased XMPPMessage
 */
+ (instancetype)messageWithType: (nullable OFString *)type
			     ID: (nullable OFString *)ID;

/*!
 * @brief Initializes an already allocated XMPPMessage with the specified ID.
 *
 * @param ID The value for the stanza's id attribute
 * @return A initialized XMPPMessage
 */
- (instancetype)initWithID: (nullable OFString *)ID;

/*!
 * @brief Initializes an already allocated XMPPMessage with the specified type.
 *
 * @param type The value for the stanza's type attribute
 * @return A initialized XMPPMessage
 */
- (instancetype)initWithType: (nullable OFString *)type;

/*!
 * @brief Initializes an already allocated XMPPMessage with the specified type
 *	  and ID.
 *
 * @param type The value for the stanza's type attribute
 * @param ID The value for the stanza's id attribute
 * @return A initialized XMPPMessage
 */
- (instancetype)initWithType: (nullable OFString *)type
			  ID: (nullable OFString *)ID OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
