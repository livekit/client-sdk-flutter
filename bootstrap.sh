#!/bin/bash

if ! command -v protoc &> /dev/null
then
  echo "protoc is required and not found. please install"
  exit 1
fi

# activate protoc
pub global activate protoc_plugin
