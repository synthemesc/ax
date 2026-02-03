//
//  Config.h
//  ax
//
//  Compile-time configuration for ax.
//  Used to configure paths when building for distribution (e.g., Homebrew).
//

#ifndef AX_CONFIG_H
#define AX_CONFIG_H

// Path to axlockd binary. Set via OTHER_CFLAGS during build:
//   OTHER_CFLAGS=-DAXLOCKD_PATH_VALUE='"/usr/local/libexec/axlockd"'
// When not set (development builds), ax uses relative path lookup.

#ifdef AXLOCKD_PATH_VALUE
static const char * const AXLOCKD_PATH = AXLOCKD_PATH_VALUE;
#else
static const char * const AXLOCKD_PATH = (const char *)0;
#endif

#endif /* AX_CONFIG_H */
