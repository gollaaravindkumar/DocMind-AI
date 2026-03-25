import os
import shutil
import urllib.parse
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List

from document_processor import process_pdf
from vector_store import VectorStore
from rag_engine import RAGEngine
from pydantic import BaseModel
from fastapi.responses import FileResponse
from podcast_generator import generate_podcast_script
from tts_engine import generate_podcast_audio

PODCAST_DIR = "./podcasts"
os.makedirs(PODCAST_DIR, exist_ok=True)

app = FastAPI(title="DocMind AI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

os.makedirs("uploads", exist_ok=True)

store = VectorStore()
rag = RAGEngine(store)

class AskRequest(BaseModel):
    question: str

class PodcastRequest(BaseModel):
    filename: str

@app.post("/podcast/generate")
async def generate_podcast(req: PodcastRequest):
    filepath = os.path.join("uploads", req.filename)
    if not os.path.exists(filepath):
        raise HTTPException(status_code=404, detail="Document not found")
    
    try:
        script = generate_podcast_script(filepath)
        audio_name = f"{req.filename}.mp3"
        audio_path = os.path.join(PODCAST_DIR, audio_name)
        generate_podcast_audio(script, audio_path)
        return {
            "status": "success", 
            "audio_url": f"/podcast/audio/{urllib.parse.quote(audio_name)}", 
            "script": script
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Podcast generation failed: {str(e)}")

@app.get("/podcast/audio/{audio_name}")
async def get_podcast_audio(audio_name: str):
    filepath = os.path.join(PODCAST_DIR, audio_name)
    if not os.path.exists(filepath):
        raise HTTPException(status_code=404, detail="Audio not found")
    return FileResponse(filepath, media_type="audio/mpeg")

@app.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Only PDF files are supported")
        
    file_path = os.path.join("uploads", file.filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    try:
        chunks = process_pdf(file_path, file.filename)
        store.add_chunks(chunks)
        
        # update metadata list with some stats
        pages = set(c["metadata"]["page_number"] for c in chunks)
        return {
            "message": "Document processed and stored successfully", 
            "filename": file.filename,
            "chunks_stored": len(chunks),
            "pages": len(pages)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/ask")
async def ask_question(req: AskRequest):
    if not req.question:
        raise HTTPException(status_code=400, detail="Question cannot be empty")
    
    result = rag.ask(req.question)
    return result

@app.get("/documents")
async def list_documents():
    doc_chunks = {}
    doc_pages = {}
    for item in store.metadata:
        filename = item["metadata"]["filename"]
        doc_chunks[filename] = doc_chunks.get(filename, 0) + 1
        if filename not in doc_pages:
            doc_pages[filename] = set()
        doc_pages[filename].add(item["metadata"]["page_number"])
        
    documents = []
    for filename in doc_chunks:
        documents.append({
            "filename": filename,
            "chunks": doc_chunks[filename],
            "page_count": len(doc_pages[filename])
        })
        
    return {"documents": documents}

@app.get("/documents/{name}")
async def get_document(name: str):
    file_path = os.path.join("uploads", name)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Document not found")
    return FileResponse(file_path, media_type="application/pdf")

from fastapi import Response
import fitz

@app.get("/documents/{name}/page/{page}")
async def get_document_page(name: str, page: int):
    file_path = os.path.join("uploads", name)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Document not found")
        
    doc = fitz.open(file_path)
    if page < 1 or page > len(doc):
        doc.close()
        raise HTTPException(status_code=400, detail="Invalid page number")
        
    new_doc = fitz.open()
    new_doc.insert_pdf(doc, from_page=page-1, to_page=page-1)
    
    pdf_bytes = new_doc.write()
    new_doc.close()
    doc.close()
    
    return Response(content=pdf_bytes, media_type="application/pdf")

@app.delete("/documents/{name}")
async def delete_document(name: str):
    store.remove_document(name)
    file_path = os.path.join("uploads", name)
    if os.path.exists(file_path):
        os.remove(file_path)
    return {"message": f"Document {name} deleted"}

@app.get("/health")
async def health_check():
    import requests
    ollama_status = "offline"
    try:
        res = requests.get("http://localhost:11434/")
        if res.status_code == 200:
            ollama_status = "online"
    except:
        pass
        
    return {
        "status": "ok",
        "faiss_index_size": store.index.ntotal,
        "ollama_status": ollama_status
    }

@app.delete("/reset")
async def reset_backend():
    store.reset()
    rag.conversation_memory = []
    
    if os.path.exists("uploads"):
        shutil.rmtree("uploads")
    os.makedirs("uploads", exist_ok=True)
    
    return {"message": "Backend reset successfully"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8002, reload=True)
