#include <stdio.h>
#include <stdlib.h>
#include "objc/runtime.h"

/**
 * The handler installed with objc_setEnumerationMutationHandler(), or NULL if
 * none has been installed.
 */
static void (*enumerationMutationHandler)(id);

OBJC_PUBLIC
void objc_setEnumerationMutationHandler(void (*handler)(id))
{
	__atomic_store_n(&enumerationMutationHandler, handler, __ATOMIC_RELEASE);
}

// This function is exported as a weak symbol to enable GNUstep or some other
// framework to replace it trivially.  Replacing it only works if the
// replacement is found before this definition, which depends on link order,
// so frameworks should install a handler with
// objc_setEnumerationMutationHandler() instead.
OBJC_PUBLIC
void __attribute__((weak)) objc_enumerationMutation(id obj)
{
	void (*handler)(id) =
		__atomic_load_n(&enumerationMutationHandler, __ATOMIC_ACQUIRE);
	if (NULL != handler)
	{
		handler(obj);
		return;
	}
	fprintf(stderr, "Mutation occurred during enumeration.");
	abort();
}
