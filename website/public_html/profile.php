<?php
declare(strict_types=1);

// Landing page for a scanned profile QR code or a shared profile link. Phones
// with GymFeed installed open the app directly through App Links / Universal
// Links and never reach this page.

const APP_STORE_URL = 'https://apps.apple.com/app/gymfeed/id6480524639';
const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.flutterflow.gymfeedofficial';

$username = trim((string)($_GET['u'] ?? ''));
$valid = preg_match('/^[A-Za-z0-9_.-]{1,40}$/', $username) === 1;

http_response_code($valid ? 200 : 404);
header('Content-Type: text/html; charset=utf-8');
header('Cache-Control: public, max-age=300');
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: no-referrer');
header("Content-Security-Policy: default-src 'none'; img-src 'self'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'");

if ($_SERVER['REQUEST_METHOD'] === 'HEAD') {
    exit;
}

$handle = htmlspecialchars($username, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
$encoded = rawurlencode($username);
$appUrl = 'com.flutterflow.gymfeedofficial:/profileOther?username='.$encoded;
$webUrl = 'https://gymfeed.io/profileOther?username='.$encoded;
$title = $valid ? '@'.$handle.' on GymFeed' : 'GymFeed';
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title><?= $title ?></title>
<?php if ($valid): ?>
<link rel="canonical" href="https://gymfeed.io/u/<?= $encoded ?>">
<meta property="og:title" content="<?= $title ?>">
<meta property="og:description" content="See this profile on GymFeed.">
<?php endif; ?>
<link rel="icon" href="/assets/app-icon.png">
<style>
body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;background:#090909;color:#fff;font-family:Poppins,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
main{width:100%;max-width:380px;padding:32px 24px;text-align:center;box-sizing:border-box}
img{width:76px;height:76px;border-radius:20px}
h1{font-size:24px;margin:18px 0 6px;word-break:break-word}
p{color:#9a9a9a;font-size:15px;margin:0 0 24px;line-height:1.45}
a{display:block;padding:14px;border-radius:14px;text-decoration:none;font-weight:600;margin-top:10px}
.open{background:#16e77d;color:#06150c}
.store{border:1px solid #343434;color:#fff}
.web{color:#9a9a9a;font-weight:400;font-size:14px}
</style>
</head>
<body>
<main>
<img src="/assets/app-icon.png" alt="GymFeed">
<?php if ($valid): ?>
<h1>@<?= $handle ?> is on GymFeed</h1>
<p>Open the profile in the app, or get GymFeed to follow them.</p>
<a class="open" href="<?= htmlspecialchars($appUrl, ENT_QUOTES, 'UTF-8') ?>">Open in GymFeed</a>
<?php else: ?>
<h1>Profile not found</h1>
<p>This GymFeed profile link is not valid.</p>
<?php endif; ?>
<a class="store" href="<?= APP_STORE_URL ?>">Download on the App Store</a>
<a class="store" href="<?= PLAY_STORE_URL ?>">Get it on Google Play</a>
<?php if ($valid): ?>
<a class="web" href="<?= htmlspecialchars($webUrl, ENT_QUOTES, 'UTF-8') ?>">Continue on the web</a>
<?php endif; ?>
</main>
</body>
</html>
