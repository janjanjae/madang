#!/bin/sh
# madang 빌드 — Xcode 불필요, Command Line Tools의 swiftc만 있으면 된다
cd "$(dirname "$0")" && swiftc -O -framework AppKit -o madang madang.swift && echo "built: $(pwd)/madang"
