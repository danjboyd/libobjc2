#include "Test.h"
#include "../ivar.h"

@interface ModernWeakIvarOwnershipProbe : Test
{
	__weak id weakValue;
	__strong id strongValue;
	__unsafe_unretained id unsafeValue;
}
@end

@implementation ModernWeakIvarOwnershipProbe
@end

static void assertOwnership(const char *name, objc_ivar_ownership expected)
{
	Ivar ivar = class_getInstanceVariable([ModernWeakIvarOwnershipProbe class], name);
	assert(ivar != NULL);
	assert(ivarGetOwnership(ivar) == expected);
}

int main(void)
{
	/*
	 * Characterization test: the modern GNUstep runtime exposes ownership via
	 * per-ivar flags and compiler-generated ARC cleanup, while the Apple weak
	 * layout API remains unsupported.
	 */
	SEL cxxDestruct = sel_registerName(".cxx_destruct");

	assert(class_getWeakIvarLayout([ModernWeakIvarOwnershipProbe class]) == NULL);
	assert(class_getInstanceMethod([ModernWeakIvarOwnershipProbe class], cxxDestruct) != NULL);

	assertOwnership("weakValue", ownership_weak);
	assertOwnership("strongValue", ownership_strong);
	assertOwnership("unsafeValue", ownership_unsafe);

	return 0;
}
