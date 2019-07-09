// Copyright (c) 2014 ARRIS Enterprises, Inc. All rights reserved.
//
// This program is confidential and proprietary to ARRIS Enterprises, Inc.
// (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
// published or used, in whole or in part, without the express prior written
// permission of ARRIS.

#ifndef MAKESYSTEM_VISIBILITY_H
#define MAKESYSTEM_VISIBILITY_H

#define EXPORT __attribute__ ((visibility ("default")))
#define LOCAL __attribute__ ((visibility ("hidden")))
#define EXPORT_BEGIN _Pragma("GCC visibility push(default)")
#define EXPORT_END _Pragma("GCC visibility pop")
#define LOCAL_BEGIN _Pragma("GCC visibility push(hidden)")
#define LOCAL_END _Pragma("GCC visibility pop")

#endif // MAKESYSTEM_VISIBILITY_H
