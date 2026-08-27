import { validateCalendarConfig, type CalendarConfig } from "./calendar";
import { adminPageHtml } from "./adminPage";

export interface Env {
  CALENDAR_KV: KVNamespace;
}

const KV_KEY = "calendar";
const EMPTY_CONFIG: CalendarConfig = { closedDates: [], openDates: [] };

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/api/calendar" && request.method === "GET") {
      return getCalendar(env);
    }

    if (url.pathname === "/admin" && request.method === "GET") {
      return new Response(adminPageHtml, {
        headers: { "content-type": "text/html; charset=utf-8" },
      });
    }

    if (url.pathname === "/admin/api/calendar" && request.method === "GET") {
      return getCalendar(env);
    }

    if (url.pathname === "/admin/api/calendar" && request.method === "PUT") {
      return putCalendar(request, env);
    }

    return new Response("not found", { status: 404 });
  },
};

async function getCalendar(env: Env): Promise<Response> {
  const raw = await env.CALENDAR_KV.get(KV_KEY);
  const body = raw ?? JSON.stringify(EMPTY_CONFIG);
  return new Response(body, {
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

async function putCalendar(request: Request, env: Env): Promise<Response> {
  let parsed: unknown;
  try {
    parsed = await request.json();
  } catch {
    return new Response("invalid JSON body", { status: 400 });
  }

  let config: CalendarConfig;
  try {
    config = validateCalendarConfig(parsed);
  } catch (err) {
    return new Response(`invalid calendar config: ${(err as Error).message}`, {
      status: 400,
    });
  }

  await env.CALENDAR_KV.put(KV_KEY, JSON.stringify(config));
  return new Response(JSON.stringify(config), {
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}
