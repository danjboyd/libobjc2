#include "Test.h"
#include "../objc/objc-arc.h"

/*
 * objc_retainAutoreleasedReturnValue() may take over the reference of an
 * object returned with objc_autoreleaseReturnValue(), but must not take an
 * object out of the autorelease pool just because it is the pool's most
 * recent entry: a method can return an object that it does not own and that
 * other code autoreleased earlier and still relies on.
 */

static int deallocated;

@interface Canary : Test
@end
@implementation Canary
- (void)dealloc
{
	deallocated++;
	[super dealloc];
}
@end

@interface Holder : Test
{
	@public
	id object;
}
@end
@implementation Holder
/* Returns the instance variable at +0, as a non-ARC getter does. */
- (id)object
{
	return object;
}
@end

/* Returns a new object as an ARC method does. */
static id newAutoreleasedReturnValue(void)
{
	return objc_autoreleaseReturnValue([Canary new]);
}

int main()
{
	@autoreleasepool
	{
		Holder *holder = [Holder new];
		/* Autoreleased by non-ARC code that keeps using it, unowned. */
		id canary = [[Canary new] autorelease];
		holder->object = canary;
		/* An ARC caller of -object: retains the result, then releases it. */
		id result = objc_retainAutoreleasedReturnValue([holder object]);
		assert(result == canary);
		objc_release(result);
		assert(deallocated == 0);
		/* The non-ARC code's reference from the pool is still good. */
		assert(objc_retain(canary) == canary);
		objc_release(canary);
		[holder release];
	}
	assert(deallocated == 1);

	/* A value returned with objc_autoreleaseReturnValue() and taken over at
	   once is not left in the pool. */
	deallocated = 0;
	@autoreleasepool
	{
		id result = objc_retainAutoreleasedReturnValue(newAutoreleasedReturnValue());
		objc_release(result);
		assert(deallocated == 1);
	}
	assert(deallocated == 1);

	/* One that is not taken over lives until the pool is popped. */
	deallocated = 0;
	@autoreleasepool
	{
		newAutoreleasedReturnValue();
		assert(deallocated == 0);
	}
	assert(deallocated == 1);

	/* Including when another one is returned after it, and neither is taken
	   over. */
	deallocated = 0;
	@autoreleasepool
	{
		newAutoreleasedReturnValue();
		newAutoreleasedReturnValue();
		assert(deallocated == 0);
	}
	assert(deallocated == 2);

	/* An inner pool does not dispose of a value returned before it. */
	deallocated = 0;
	@autoreleasepool
	{
		newAutoreleasedReturnValue();
		@autoreleasepool
		{
			[[Canary new] autorelease];
		}
		assert(deallocated == 1);
	}
	assert(deallocated == 2);

	return 0;
}
