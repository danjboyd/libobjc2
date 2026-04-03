#include "Test.h"

@interface WeakLayoutProbe : Test
{
	__weak id weakValue;
	id strongValue;
}
@end

@implementation WeakLayoutProbe
@end

int main(void)
{
	/*
	 * Characterization test: the modern v2 runtime does not currently expose
	 * weak ivar layout metadata through the Apple-compatible layout APIs.
	 */
	assert(class_getWeakIvarLayout([WeakLayoutProbe class]) == NULL);

	Class dynamic = objc_allocateClassPair([Test class], "WeakLayoutDynamicProbe", 0);
	assert(dynamic != Nil);
	class_setWeakIvarLayout(dynamic, class_getIvarLayout([WeakLayoutProbe class]));
	assert(class_getWeakIvarLayout(dynamic) == NULL);
	objc_disposeClassPair(dynamic);
	return 0;
}
