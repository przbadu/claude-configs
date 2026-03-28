## Introduction

This is a skills for procurmentexpress.com public API documentation.

**SKILL PATH**: @/Users/przbadu/.claude/skills/procurementexpress-skills/
**BACKEND API PATH:**
- V1 API: /Users/przbadu/projects/pex/po-app/app/controllers/api/v1
- V3 API: /Users/przbadu/projects/pex/po-app/app/controllers/api/v3 IMPORTANT NOTE: V3 API supports oauth2 authentication, apart from that all the features are identical with v1 api, so always read v1 API implementation.

**Official documentation**: https://r.jina.ai/docs.procurementexpress.com

## What is completed

Current skills was extracted from the official MCP skills, so this skills uses the MCP version.

## Requirements

- Current skills is outdated
- It heavily depends on MCP, whereas I want to build this MCP using `curl` e.g:
---
name: curl-requests-to-po-app
description: This skill provides examples of curl requests to interact with the ProcurementExpress (po-app) API. Use when: you need to test or interact with the po-app API endpoints via curl commands, such as creating purchase orders, taxes, managing suppliers, or authenticating users.
---

# curl-requests-to-po-app

Examples of curl requests to interact with the ProcurementExpress (po-app) API.

## Base URL

```
http://localhost:3000/api/v1
```

## Authentication

All API requests (except login) require these headers:

```
authentication_token: <user_token>
app_company_id: <company_id>
Content-Type: application/json
```

---

## Authentication

### Login

```bash
curl -s -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@rubberstamp.io", "password": "rubberst@mp99"}'
```

**Response includes:**

- `authentication_token` - Use this for subsequent requests
- `companies[].id` - Use as `app_company_id`

### Get Current User

```bash
curl -s http://localhost:3000/api/v1/currentuser \
  -H "authentication_token: <token>" \
  -H "app_company_id: <company_id>"
```

---

## Purchase Orders

### List Purchase Orders

```bash
curl -s http://localhost:3000/api/v1/purchase_orders \
  -H "authentication_token: <token>" \
  -H "app_company_id: <company_id>"
```

### Get Purchase Order by ID

```bash
curl -s http://localhost:3000/api/v1/purchase_orders/1 \
  -H "authentication_token: <token>" \
  -H "app_company_id: <company_id>"
```

## Technical GUIDE

- Our backend app is using Ruby on Rails API so always follow ruby on rails best practice to build up to date skills.
- All the supported POST/PUT params/fields are mentioned in strong params that looks like `po_params`, `supplier_params`, etc, so check for strong params in the controller, and keep up to date params in the skills.
- GET params like Listing and Details API uses ActiveModelSerializer so always check corresponding serializer like purchase_order_serializer.rb, purchase_order_details_serializer.rb, company_setting_serializer.rb, company_serializer.rb, to see up to date serializer values that will be returned by the API.

