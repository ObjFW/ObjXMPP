/*
 * Copyright (c) 2013, Florian Zeitz <florob@babelmonkeys.de>
 * Copyright (c) 2013, 2016, 2021, Jonathan Schleifer <js@nil.im>
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

/*!
 * @brief A class describing a Service Discovery Identity
 */
@interface XMPPDiscoIdentity: OFObject <OFComparing>
{
	OFString *_category, *_name, *_type;
}

/*!
 * The category of the identity.
 */
@property (readonly, nonatomic) OFString *category;

/*!
 * The name of the identity, might be unset.
 */
@property (readonly, nonatomic) OFString *name;

/*!
 * The type of the identity.
 */
@property (readonly, nonatomic) OFString *type;

/*!
 * @brief Creates a new autoreleased XMPPDiscoIdentity with the specified
 *	  category, type and name.
 *
 * @param category The category of the identity
 * @param type The type of the identity
 * @param name The name of the identity
 * @return A new autoreleased XMPPDiscoIdentity
 */
+ (instancetype)identityWithCategory: (OFString *)category
				type: (OFString *)type
				name: (nullable OFString *)name;

/*!
 * @brief Creates a new autoreleased XMPPDiscoIdentity with the specified
 *	  category and type.
 *
 * @param category The category of the identity
 * @param type The type of the identity
 * @return A new autoreleased XMPPDiscoIdentity
 */
+ (instancetype)identityWithCategory: (OFString *)category
				type: (OFString *)type;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated XMPPDiscoIdentity with the specified
 *	  category, type and name.
 *
 * @param category The category of the identity
 * @param type The type of the identity
 * @param name The name of the identity
 * @return An initialized XMPPDiscoIdentity
 */
- (instancetype)initWithCategory: (OFString *)category
			    type: (OFString *)type
			    name: (nullable OFString *)name
    OF_DESIGNATED_INITIALIZER;

/*!
 * @brief Initializes an already allocated XMPPDiscoIdentity with the specified
 *	  category and type.
 *
 * @param category The category of the identity
 * @param type The type of the identity
 * @return An initialized XMPPDiscoIdentity
 */
- (instancetype)initWithCategory: (OFString *)category type: (OFString *)type;
@end

OF_ASSUME_NONNULL_END
