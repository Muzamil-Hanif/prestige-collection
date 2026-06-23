---
description: Check if the NestJS backend is reachable and list available endpoints
allowed-tools: Bash(curl *) Read(lib/services/api_config.dart)
---

Test backend connectivity:

1. Run `curl -s http://127.0.0.1:3000/api/docs -o /dev/null -w "%{http_code}"` and report the HTTP status.
2. Read `lib/services/api_config.dart` and list all defined endpoint constants.
3. Report which GET endpoints are reachable by probing them with curl.
