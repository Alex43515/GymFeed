<?php
declare(strict_types=1);

const SUPABASE_USER_ENDPOINT = 'https://bzinwojowkxavfzilvat.supabase.co/auth/v1/user';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_iyY6WXUGOBK2pkePZFZurw_ZIStK1ge';
const MODERATION_EMAIL = 'official@gymfeed.io';

function respond(int $status, array $payload): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    header('X-Content-Type-Options: nosniff');
    echo json_encode($payload, JSON_UNESCAPED_SLASHES);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    $origin = (string)($_SERVER['HTTP_ORIGIN'] ?? '');
    if ($origin === 'https://gymfeed.io' || $origin === 'https://www.gymfeed.io') {
        header('Access-Control-Allow-Origin: '.$origin);
        header('Vary: Origin');
    }
    header('Access-Control-Allow-Headers: Authorization, Content-Type');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(405, ['ok' => false, 'error' => 'Method not allowed']);
}

$origin = (string)($_SERVER['HTTP_ORIGIN'] ?? '');
if ($origin !== '') {
    if ($origin !== 'https://gymfeed.io' && $origin !== 'https://www.gymfeed.io') {
        respond(403, ['ok' => false, 'error' => 'Origin not allowed']);
    }
    header('Access-Control-Allow-Origin: '.$origin);
    header('Vary: Origin');
}

$authorization = trim((string)($_SERVER['HTTP_AUTHORIZATION'] ?? ''));
if (!preg_match('/^Bearer\s+(.+)$/i', $authorization, $matches)) {
    respond(401, ['ok' => false, 'error' => 'Authentication required']);
}
$accessToken = trim($matches[1]);

$authContext = stream_context_create([
    'http' => [
        'method' => 'GET',
        'timeout' => 8,
        'ignore_errors' => true,
        'header' => "Authorization: Bearer {$accessToken}\r\napikey: ".SUPABASE_PUBLISHABLE_KEY."\r\nAccept: application/json\r\n",
    ],
]);
$userJson = @file_get_contents(SUPABASE_USER_ENDPOINT, false, $authContext);
$user = is_string($userJson) ? json_decode($userJson, true) : null;
if (!is_array($user) || !isset($user['id'])) {
    respond(401, ['ok' => false, 'error' => 'Invalid session']);
}

// Authenticated per-user throttling prevents the mail relay from being abused.
$rateFile = sys_get_temp_dir().'/gymfeed-report-'.hash('sha256', (string)$user['id']).'.json';
$now = time();
$events = [];
$handle = @fopen($rateFile, 'c+');
if ($handle !== false && flock($handle, LOCK_EX)) {
    $raw = stream_get_contents($handle);
    $stored = is_string($raw) ? json_decode($raw, true) : null;
    if (is_array($stored)) {
        $events = array_values(array_filter($stored, static fn($t) => is_int($t) && $t > $now - 3600));
    }
    if (count($events) >= 10) {
        flock($handle, LOCK_UN);
        fclose($handle);
        respond(429, ['ok' => false, 'error' => 'Too many reports. Try again later.']);
    }
    $events[] = $now;
    ftruncate($handle, 0);
    rewind($handle);
    fwrite($handle, json_encode($events));
    fflush($handle);
    flock($handle, LOCK_UN);
    fclose($handle);
}

$payload = json_decode((string)file_get_contents('php://input'), true);
if (!is_array($payload)) {
    respond(400, ['ok' => false, 'error' => 'Invalid request']);
}

$uuid = '/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i';
$reportId = trim((string)($payload['report_id'] ?? ''));
$contentId = trim((string)($payload['content_id'] ?? ''));
$reportedUserId = trim((string)($payload['reported_user_id'] ?? ''));
$contentType = trim((string)($payload['content_type'] ?? ''));
$reason = trim((string)($payload['reason'] ?? ''));
$details = trim((string)($payload['details'] ?? ''));
$imageUrl = trim((string)($payload['image_url'] ?? ''));

if (!preg_match($uuid, $reportId) || !preg_match($uuid, $contentId) ||
    !preg_match($uuid, $reportedUserId) ||
    !in_array($contentType, ['post', 'food_post', 'workout', 'account'], true) ||
    $reason === '') {
    respond(422, ['ok' => false, 'error' => 'Incomplete report']);
}

$clean = static fn(string $value, int $limit): string => substr(preg_replace('/[\x00-\x1F\x7F]/u', ' ', $value) ?? '', 0, $limit);
$subject = '[GymFeed moderation] '.ucwords(str_replace('_', ' ', $contentType)).' report';
$body = "A new GymFeed content report was filed.\n\n"
    ."Report ID: {$reportId}\n"
    ."Reporter ID: ".$clean((string)$user['id'], 80)."\n"
    ."Reported user ID: ".$clean($reportedUserId, 80)."\n"
    ."Content type: ".$clean($contentType, 30)."\n"
    ."Content ID: ".$clean($contentId, 80)."\n"
    ."Reason: ".$clean($reason, 200)."\n"
    ."Details: ".$clean($details, 1500)."\n"
    ."Media: ".$clean($imageUrl, 1000)."\n\n"
    ."Review this report in the Supabase reports table.";

$headers = [
    'From: GymFeed Moderation <official@gymfeed.io>',
    'Reply-To: official@gymfeed.io',
    'Content-Type: text/plain; charset=UTF-8',
    'X-Mailer: GymFeed',
];

if (!@mail(MODERATION_EMAIL, $subject, $body, implode("\r\n", $headers))) {
    respond(502, ['ok' => false, 'error' => 'Report stored; email delivery failed']);
}

respond(202, ['ok' => true, 'queued' => true]);
