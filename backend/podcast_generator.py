import json
import requests
import fitz

def extract_text_from_pdf(filepath: str) -> str:
    text = ""
    try:
        with fitz.open(filepath) as doc:
            for page in doc:
                text += page.get_text() + "\n"
    except Exception as e:
        print(f"Error reading PDF: {e}")
    return text

def generate_podcast_script(filepath: str) -> list:
    """Read a document and generate a 2-host podcast script using Gemma3."""
    text = extract_text_from_pdf(filepath)
    # Allow up to ~8000 tokens to feed the full document into the Gemini/Llama context window
    text = text[:32000]
    
    prompt = f"""You are a professional podcast writer. 
Task: Write a very long, high-quality, in-depth podcast script discussing the ENTIRE provided document.
Hosts:
- HOST_A: Main host, enthusiastic, asks clarifying questions.
- HOST_B: Expert guest, deeply analyzes concepts, explains methods, and brings up statistics.

CRITICAL INSTRUCTION: 
Your response MUST be an extensive, highly detailed dialogue containing AT LEAST 20 individual speaking turns (alternating between HOST_A and HOST_B). 
Do NOT write a short summary. You must unpack the entire document section by section.

Document text:
{text}

Output the script AS A STRICTLY VALID JSON ARRAY of objects. 
Each object must have exactly two keys: "speaker" (either "HOST_A" or "HOST_B") and "text" (what they say).
DO NOT wrap the JSON in markdown code blocks. Output ONLY raw JSON array. Start your response directly with [ and end with ].

MANDATORY EXAMPLE FORMAT:
[
  {{"speaker": "HOST_A", "text": "Welcome to the podcast! Today we are doing a massive deep dive into this document..."}},
  {{"speaker": "HOST_B", "text": "That's right! Let's begin by breaking down the introduction..."}},
  {{"speaker": "HOST_A", "text": "Interesting. And what exactly does the methodology say about..."}},
  {{"speaker": "HOST_B", "text": "The methodology is quite specific, it states that..."}},
  {{"speaker": "HOST_A", "text": "I see..."}}
  ... (YOU MUST CONTINUE ALTERNATING HOSTS FOR AT LEAST 20 MORE TURNS UNTIL THE ENTIRE PDF IS COVERED!) ...
]
"""
    try:
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": "gemma3:latest",
                "prompt": prompt,
                "stream": False,
                "options": {
                    "num_predict": 8192,
                    "temperature": 0.7
                }
            },
            timeout=600
        )
        response.raise_for_status()
        output = response.json().get("response", "[]").strip()
        
        # Clean markdown formatting if the model adds it
        if output.startswith("```json"):
            output = output[7:]
        elif output.startswith("```"):
            output = output[3:]
        if output.endswith("```"):
            output = output[:-3]
        
        output = output.strip()
        script = json.loads(output)
        if isinstance(script, dict):
            script = [script]
        elif isinstance(script, str):
            script = [{"speaker": "HOST_A", "text": script}]
        return script
    except Exception as e:
        print(f"Error generating script: {e}")
        return [
            {"speaker": "HOST_A", "text": "Welcome to the DocMind AI podcast!"},
            {"speaker": "HOST_B", "text": f"Unfortunately we couldn't generate the script right now. Error: {str(e)}"}
        ]
