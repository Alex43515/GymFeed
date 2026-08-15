<?php
declare(strict_types=1);

const SUPABASE_SHARE_ENDPOINT = 'https://bzinwojowkxavfzilvat.supabase.co/functions/v1/share-post/';
const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.flutterflow.gymfeedofficial';

function renderError(string $title, string $message, int $status): void
{
    http_response_code($status);
    header('Content-Type: text/html; charset=utf-8');
    $safeTitle = htmlspecialchars($title, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    $safeMessage = htmlspecialchars($message, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    echo '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#080808"><link rel="icon" href="/assets/app-icon.png"><link rel="stylesheet" href="/assets/site.css"><title>'.$safeTitle.' · GymFeed</title></head><body><main class="legal-shell"><header class="legal-head"><a class="brand" href="/"><img src="/assets/app-icon.png" alt="" width="42" height="42"><span>GymFeed</span></a></header><article class="support-card"><h1>'.$safeTitle.'</h1><p>'.$safeMessage.'</p><a class="button" href="'.PLAY_STORE_URL.'">Get GymFeed</a></article></main></body></html>';
    exit;
}

$id = trim((string)($_GET['id'] ?? ''));
if (!preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i', $id)) {
    renderError('Invalid post link', 'This GymFeed post link is not valid.', 400);
}

$upstream = SUPABASE_SHARE_ENDPOINT.rawurlencode($id);
$context = stream_context_create([
    'http' => [
        'method' => $_SERVER['REQUEST_METHOD'] === 'HEAD' ? 'HEAD' : 'GET',
        'timeout' => 8,
        'ignore_errors' => true,
        'header' => "Accept: text/html\r\nUser-Agent: GymFeed-Web/1.0\r\n",
    ],
]);

$html = @file_get_contents($upstream, false, $context);
$status = 502;
foreach (($http_response_header ?? []) as $headerLine) {
    if (preg_match('/^HTTP\/\S+\s+(\d{3})/', $headerLine, $match)) {
        $status = (int)$match[1];
        break;
    }
}

if ($html === false || $status >= 500) {
    renderError('GymFeed is temporarily unavailable', 'Please try opening this post again shortly.', 502);
}

http_response_code($status);
header('Content-Type: text/html; charset=utf-8');
header('Cache-Control: public, max-age=60, stale-while-revalidate=300');
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: no-referrer');
header("Content-Security-Policy: default-src 'none'; img-src https: data:; style-src 'unsafe-inline'; script-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'");

if ($_SERVER['REQUEST_METHOD'] === 'HEAD') {
    exit;
}

$publicUrl = 'https://gymfeed.io/post/'.rawurlencode($id);
$webAppUrl = 'https://gymfeed.io/postDetails?post='.rawurlencode($id);
$html = preg_replace('/<link rel="canonical" href="[^"]*">/i', '<link rel="canonical" href="'.$publicUrl.'"><meta property="og:url" content="'.$publicUrl.'">', $html, 1) ?? $html;
$html = str_replace(' Â· GymFeed', ' · GymFeed', $html);
$html = str_replace('</style>', '.web-open{display:block;margin-top:10px;border:1px solid #343434;color:#fff;text-decoration:none;font-weight:700;padding:15px;border-radius:999px}</style>', $html);
$html = str_replace('<p class="hint">', '<a class="web-open" href="'.$webAppUrl.'">Continue on the web</a><p class="hint">', $html);
$html = preg_replace('/<script>const app=.*?<\/script>/s', '', $html) ?? $html;
echo $html;
