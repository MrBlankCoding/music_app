# Simple Music App Built With Flutter

You can search for music and download it locally to your device using YT-DLP. Needs UI help if someone would like to do that. 


## Prerequisites
1. YT API v3 API key
    -(Its free and its needed for searching YT)

## ENV
Create your .env in the root

```env
YOUTUBE_API_KEY=YOUR_API_KEY_HERE
```

## Errors
If anything is going wrong it is most likely one of three things. 
1. Its not allowing HTTP requests
    -> Allow outgoing network connections for your build platform
2. It doesnt like the execution of the YT-DLP binary
    -> Turn off sandboxing
3. Audio files arent processing after downloading
    -> Make sure FFMPEG is downloaded and accesible
