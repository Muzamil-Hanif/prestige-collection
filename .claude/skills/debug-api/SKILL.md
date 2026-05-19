---
name: debug-api
description: Test NestJS backend API connectivity and probe key endpoints
allowed-tools: Bash(curl *) Read(lib/services/api_config.dart)
---

## Backend Status

!`curl -s http://127.0.0.1:3000/api/docs -o /dev/null -w "HTTP %{http_code}" 2>&1 || echo "Backend unreachable"`

## Defined Endpoints (from ApiConfig)

Read `lib/services/api_config.dart` and list every endpoint constant.

## Actions

Probe GET endpoints with curl and report which ones respond. Flag any 4xx/5xx responses.
