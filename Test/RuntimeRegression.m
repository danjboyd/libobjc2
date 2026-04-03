#include "Test.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "../selector.h"

@protocol RuntimeRegressionProtocolA @end
@protocol RuntimeRegressionProtocolB @end

static void testTypedSelectorDivergence(void)
{
	/*
	 * The modern GNUstep runtime keeps typed selector variants distinct while
	 * still mapping them back to the same untyped selector name.
	 */
	SEL untyped = sel_registerName("runtimeRegressionSelector");
	SEL typedInt = sel_registerTypedName_np("runtimeRegressionSelector", "i@:");
	SEL typedId = sel_registerTypedName_np("runtimeRegressionSelector", "@@:");

	assert(sel_isEqual(untyped, typedInt));
	assert(sel_isEqual(untyped, typedId));
	assert(!sel_isEqual(typedInt, typedId));
	assert(strcmp(sel_getName(typedInt), "runtimeRegressionSelector") == 0);
	assert(strcmp(sel_getName(typedId), "runtimeRegressionSelector") == 0);
}

static void testDynamicProtocolRegistration(void)
{
	Protocol *dynamic = objc_allocateProtocol("RuntimeRegressionProtocol");
	assert(dynamic != NULL);

	protocol_addProtocol(dynamic, @protocol(RuntimeRegressionProtocolA));
	protocol_addProtocol(dynamic, @protocol(RuntimeRegressionProtocolB));
	objc_registerProtocol(dynamic);

	Protocol *registered = objc_getProtocol("RuntimeRegressionProtocol");
	assert(registered == dynamic);
	assert(protocol_isEqual(dynamic, registered));
	assert(protocol_conformsToProtocol(registered, @protocol(RuntimeRegressionProtocolA)));
	assert(protocol_conformsToProtocol(registered, @protocol(RuntimeRegressionProtocolB)));

	unsigned int count = 0;
	Protocol **list = objc_copyProtocolList(&count);
	assert(list != NULL);

	BOOL found = NO;
	for (unsigned int i = 0; i < count; i++)
	{
		if (protocol_isEqual(list[i], dynamic))
		{
			found = YES;
			break;
		}
	}
	assert(found);
	free(list);
}

int main(void)
{
	testTypedSelectorDivergence();
	testDynamicProtocolRegistration();
	return 0;
}
