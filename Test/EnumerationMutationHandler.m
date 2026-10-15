#include "Test.h"

/*
 * objc_enumerationMutation() must call the handler installed with
 * objc_setEnumerationMutationHandler(), passing it the collection, instead of
 * aborting.
 */

struct FastEnumerationState
{
	unsigned long state;
	__unsafe_unretained id *itemsPtr;
	unsigned long *mutationsPtr;
	unsigned long extra[5];
};

static unsigned long mutations;
static id lastMutated;
static int handlerCalls;

@interface Collection : Test
- (unsigned long)countByEnumeratingWithState: (struct FastEnumerationState*)aState
                                     objects: (__unsafe_unretained id*)stackbuf
                                       count: (unsigned long)len;
@end

@implementation Collection
- (unsigned long)countByEnumeratingWithState: (struct FastEnumerationState*)aState
                                     objects: (__unsafe_unretained id*)stackbuf
                                       count: (unsigned long)len
{
	if (aState->state != 0)
	{
		return 0;
	}
	aState->state = 1;
	aState->mutationsPtr = &mutations;
	stackbuf[0] = self;
	stackbuf[1] = self;
	stackbuf[2] = self;
	aState->itemsPtr = stackbuf;
	return 3;
}
@end

static void handler(id collection)
{
	handlerCalls++;
	lastMutated = collection;
}

int main(void)
{
	Collection *collection = [Collection new];
	int iterations = 0;

	objc_setEnumerationMutationHandler(handler);

	// Iterating without mutating must not call the handler.
	for (id obj in collection)
	{
		iterations++;
	}
	assert(3 == iterations);
	assert(0 == handlerCalls);

	// Mutate once, during the first iteration.  The handler is called before
	// the second iteration and, because it returns, iteration continues.
	iterations = 0;
	for (id obj in collection)
	{
		if (0 == iterations++)
		{
			mutations++;
		}
	}
	assert(3 == iterations);
	assert(handlerCalls > 0);
	assert(lastMutated == collection);

	// Calling the runtime function directly uses the handler too.
	handlerCalls = 0;
	lastMutated = nil;
	objc_enumerationMutation(collection);
	assert(1 == handlerCalls);
	assert(lastMutated == collection);

	[collection dealloc];
	return 0;
}
