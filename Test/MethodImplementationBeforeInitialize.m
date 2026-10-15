#include "Test.h"

/*
 * class_getMethodImplementation() and class_respondsToSelector() must find
 * the methods of a class that has not yet received any message, and so has
 * no dtable.  Doing so must not disturb +initialize, which is still sent
 * exactly once, before the first message is delivered.
 */

static int initializeCount;
static int superInitializeCount;

@interface ColdSuper : Test
+ (int)inheritedClassMethod;
- (int)inheritedMethod;
@end

@interface Cold : ColdSuper
+ (int)classMethod;
- (int)method;
@end

@implementation ColdSuper
+ (void)initialize
{
	if (self == [ColdSuper class])
	{
		superInitializeCount++;
	}
}
+ (int)inheritedClassMethod
{
	return 3;
}
- (int)inheritedMethod
{
	return 4;
}
@end

@implementation Cold
+ (void)initialize
{
	if (self == [Cold class])
	{
		assert(superInitializeCount == 1);
		initializeCount++;
	}
}
+ (int)classMethod
{
	return 1;
}
- (int)method
{
	return 2;
}
@end

static IMP instanceImp(Class cls, SEL sel)
{
	return method_getImplementation(class_getInstanceMethod(cls, sel));
}

int main(void)
{
	Class cls = objc_getClass("Cold");
	Class meta = object_getClass((id)cls);
	Class superclass = objc_getClass("ColdSuper");
	Class superMeta = object_getClass((id)superclass);
	IMP forward = class_getMethodImplementation(cls, @selector(notImplemented));

	IMP method = class_getMethodImplementation(cls, @selector(method));
	IMP inheritedMethod = class_getMethodImplementation(cls, @selector(inheritedMethod));
	IMP classMethod = class_getMethodImplementation(meta, @selector(classMethod));
	IMP inheritedClassMethod =
		class_getMethodImplementation(meta, @selector(inheritedClassMethod));

	assert(method != forward);
	assert(method == instanceImp(cls, @selector(method)));
	assert(inheritedMethod == instanceImp(superclass, @selector(inheritedMethod)));
	assert(classMethod == instanceImp(meta, @selector(classMethod)));
	assert(inheritedClassMethod ==
		instanceImp(superMeta, @selector(inheritedClassMethod)));
	assert(class_respondsToSelector(cls, @selector(method)));
	assert(class_respondsToSelector(cls, @selector(inheritedMethod)));
	assert(class_respondsToSelector(meta, @selector(classMethod)));
	assert(!class_respondsToSelector(cls, @selector(notImplemented)));

	assert([Cold classMethod] == 1);
	assert(superInitializeCount == 1);
	assert(initializeCount == 1);

	// The lookups agree with the dtable once the class is initialized.
	assert(method == class_getMethodImplementation(cls, @selector(method)));
	assert(classMethod == class_getMethodImplementation(meta, @selector(classMethod)));
	assert(inheritedClassMethod ==
		class_getMethodImplementation(meta, @selector(inheritedClassMethod)));
	assert(((int(*)(id, SEL))method)([Cold new], @selector(method)) == 2);
	return 0;
}
