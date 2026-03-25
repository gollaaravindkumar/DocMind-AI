import os
from gtts import gTTS

def generate_podcast_audio(script, output_filename: str):
    """Takes a script JSON and creates an MP3 using gTTS."""
    temp_files = []
    
    # robust parsing
    valid_script = []
    if isinstance(script, str):
        valid_script = [{"speaker": "HOST_A", "text": script}]
    elif isinstance(script, list):
        for item in script:
            if isinstance(item, dict):
                valid_script.append(item)
            elif isinstance(item, str):
                if ":" in item:
                    speaker, text = item.split(":", 1)
                    valid_script.append({"speaker": speaker.strip(), "text": text.strip()})
                else:
                    valid_script.append({"speaker": "HOST_A", "text": item.strip()})
                    
    for i, line in enumerate(valid_script):
        speaker = line.get("speaker", "HOST_A")
        text = line.get("text", "")
        if not text:
            continue
            
        # Host A gets US Accent, Host B gets British Accent to distinguish voices
        tld = "com" if speaker == "HOST_A" else "co.uk"
        
        tts = gTTS(text=text, lang="en", tld=tld, slow=False)
        temp_file = f"temp_{i}.mp3"
        tts.save(temp_file)
        temp_files.append(temp_file)
        
    # Concatenate MP3s binary (works for basic playback)
    with open(output_filename, "wb") as outfile:
        for f in temp_files:
            with open(f, "rb") as infile:
                outfile.write(infile.read())
                
    # Cleanup temp files
    for f in temp_files:
        try:
            os.remove(f)
        except:
            pass
            
    return output_filename
