import type { SupabaseClient } from "@supabase/supabase-js";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
/** Shared MCP tool registrations for stdio and HTTP transports. */
export declare function createFrescopaServer(supabase: SupabaseClient): McpServer;
