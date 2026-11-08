import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { NextRequest, NextResponse } from 'next/server';
export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
async function proxy(request: NextRequest, context: { params: Promise<{ path: string[] }> }) {
  // Local preview only. Public hosting requires a real owner-authenticated session.
  // Next can normalize the internal URL to localhost even when the browser used 127.0.0.1.
  const host = request.headers.get('host')?.toLowerCase() ?? '';
  if (!/^(?:localhost|127\.0\.0\.1|\[::1\])(?::\d{1,5})?$/.test(host)) return NextResponse.json({ message: 'Owner sign-in must be configured before public access.' }, { status: 403 });
  const origin = request.headers.get('origin');
  if (origin !== null && origin !== `http://${host}`) return NextResponse.json({ message: 'Cross-origin request rejected.' }, { status: 403 });
  const { path } = await context.params;
  if (path.some(p => !/^[a-zA-Z0-9_-]+$/.test(p))) return NextResponse.json({ message: 'Invalid route' }, { status: 400 });
  const envText = await readFile(resolve(process.cwd(), '../.env'), 'utf8').catch(() => '');
  const value = (name: string) => process.env[name] || envText.match(new RegExp(`^${name}=(.*)$`, 'm'))?.[1]?.trim().replace(/^['"]|['"]$/g, '');
  const token = value('MARKETING_INTERNAL_TOKEN');
  if (!token) return NextResponse.json({ message: 'Marketing backend token is missing from the server configuration.' }, { status: 503 });
  const headers: Record<string, string> = { 'x-marketing-token': token };
  for (const key of ['content-type', 'idempotency-key', 'x-owner-verified', 'x-capture-ref', 'x-observed-actions', 'x-edit-media-type', 'x-edit-prompt']) {
    const header = request.headers.get(key); if (header) headers[key] = header;
  }
  try {
    const upstream = await fetch(`${process.env.MARKETING_API_URL || 'http://127.0.0.1:3000'}/v1/studio/${path.join('/')}`, {
      method: request.method, headers, body: request.method === 'GET' ? undefined : await request.arrayBuffer(),
      cache: 'no-store', signal: AbortSignal.timeout(path.at(-1) === 'upload' ? 120000 : 45000),
    });
    const body = (await upstream.text()).split(token).join('[redacted]');
    return new NextResponse(body, { status: upstream.status, headers: { 'content-type': 'application/json', 'cache-control': 'no-store' } });
  } catch {
    return NextResponse.json({ message: 'Marketing worker nije dostupan. Proveri da li backend radi na portu 3000; sačuvani poslovi ostaju u bazi.', code: 'WORKER_UNAVAILABLE' }, { status: 503 });
  }
}
export const GET = proxy;
export const POST = proxy;
