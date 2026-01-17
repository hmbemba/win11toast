# Package

version       = "0.1.0"
author        = "Harrison"
description   = "Windows 10/11 Toast Notifications for Nim using WinRT"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.6.0"
requires "winim >= 3.9.0"

# Tasks

task test, "Run tests":
    exec "nim c -r tests/test_toast.nim"

task example, "Run example":
    exec "nim c -r examples/simple_toast.nim"
