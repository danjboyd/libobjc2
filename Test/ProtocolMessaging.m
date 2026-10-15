#include "Test.h"
#include "../objc/Protocol.h"

/*
 * The runtime gives the Protocol class no methods, but Foundation
 * implementations may add some in a category.  Sending a message to a
 * protocol must then reach them, for protocols that the compiler emits and
 * for protocols that are still being built at run time.
 */

@protocol Probe
- (void)probe;
@end

@implementation Protocol (ProtocolMessaging)
+ (int)classAnswer
{
	return 7;
}
- (int)answer
{
	return 42;
}
@end

int main(void)
{
	Class protocolClass = objc_getClass("Protocol");
	Class protocolMeta = object_getClass((id)protocolClass);
	Class rootMeta = object_getClass((id)objc_getClass("Object"));
	assert(protocolClass != Nil);
	// Every protocol class's metaclass must be its own, inheriting from the
	// root metaclass through Protocol's, never Protocol's metaclass itself.
	assert(class_getSuperclass(protocolMeta) == rootMeta);
	const char *subclasses[] = { "ProtocolGCC", "ProtocolGSv1",
		"__IncompleteProtocol" };
	for (int i=0 ; i<sizeof(subclasses)/sizeof(*subclasses) ; i++)
	{
		Class cls = objc_getClass(subclasses[i]);
		assert(cls != Nil);
		assert(class_getSuperclass(cls) == protocolClass);
		Class meta = object_getClass((id)cls);
		assert(meta != protocolMeta);
		assert(class_isMetaClass(meta));
		assert(class_getSuperclass(meta) == protocolMeta);
	}

	// With the legacy ABI, this may be an instance of one of the subclasses.
	Protocol *p = @protocol(Probe);
	Class cls = object_getClass((id)p);
	assert((cls == protocolClass) || (class_getSuperclass(cls) == protocolClass));
	assert([(id)p answer] == 42);
	assert([protocolClass classAnswer] == 7);

	Protocol *incomplete = objc_allocateProtocol("ProtocolMessagingIncomplete");
	assert(object_getClass((id)incomplete) == objc_getClass("__IncompleteProtocol"));
	assert([(id)incomplete answer] == 42);
	objc_registerProtocol(incomplete);
	assert([(id)incomplete answer] == 42);
	return 0;
}
