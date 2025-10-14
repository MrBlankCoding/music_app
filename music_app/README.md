# Simple Music App Built With Flutter

You can search for music and download it locally to your device using YT-DLP. Needs UI help if someone would like to do that. 


## Prerequisites
1. YT API v3 API key
    -(Its free and its needed for searching YT)
2. YT-DLP
    -(Free and open source)
    -(You can get it from here: https://github.com/yt-dlp/yt-dlp)

## Installation

```bash
flutter pub get

mkdir -p binaries
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o binaries/yt-dlp
chmod +x binaries/yt-dlp
```

## ENV
Create your .env in the root

```env
YOUTUBE_API_KEY=YOUR_API_KEY_HERE
```