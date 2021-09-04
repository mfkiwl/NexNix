/*
    assert.h - contains assertion declarations
    SPDX-License-Identifier: ISC
*/

#ifdef assert
#undef assert                       // Just in case assert was already defined
#endif

// Are assertions enabled?
#ifdef NDEBUG
#define assert(unused) ((void)0)
#else
// Assertions are enabled. But should this just wrap EDK2?
#   if NEXBOOT_UEFI == 1
#   define assert ASSERT
#   else
// This ought to wrap over libc / libk then
#   define assert(expr) (lib_assert(#expr, __func__, __FILE__, __LINE__, expr))
#   endif
#endif

// Static assertions
#define static_assert _Static_assert
