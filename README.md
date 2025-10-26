# Simple Music App Built With Flutter

You can search for music and download it locally to your device using a custom download API. Needs UI help if someone would like to do that. 

## How to run the Download API

1.  Navigate to the `DownloadAPI` directory.
2.  Install the required dependencies by running `pip install -r requirements.txt`.
3.  Run the API using `uvicorn main:app --host 0.0.0.0 --port 8000 --reload`.

## Errors
If anything is going wrong it is most likely one of three things. 
1. Its not allowing HTTP requests
    -> Allow outgoing network connections for your build platform
2. It doesnt like the execution of the YT-DLP binary
    -> Turn off sandboxing
3. Audio files arent processing after downloading
    -> Make sure FFMPEG is downloaded and accesible