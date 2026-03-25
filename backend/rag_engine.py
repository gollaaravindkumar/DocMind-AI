import requests
from vector_store import VectorStore

class RAGEngine:
    def __init__(self, vector_store: VectorStore):
        self.vector_store = vector_store
        self.conversation_memory = []
        
    def ask(self, question: str):
        # Retrieve top 4 relevant chunks via FAISS
        relevant_chunks = self.vector_store.search(question, top_k=4)
        
        context_parts = []
        sources = []
        
        for chunk in relevant_chunks:
            filename = chunk["metadata"]["filename"]
            page = chunk["metadata"]["page_number"]
            sources.append({
                "filename": filename, 
                "page_number": page, 
                "text": chunk["text"],
                "score": chunk.get("score", 0.0),
                "chunk_id": chunk.get("chunk_id", -1)
            })
            context_parts.append(f"[Source: {filename}, Page: {page}]\n{chunk['text']}")
            
        context = "\n\n".join(context_parts)
        
        # Build prompt
        system_prompt = (
            "You are DocMind AI, an expert QA system. Answer the user's question purely based on the context provided. "
            "If the answer is not in the context, say 'I don't have enough information to answer that.'\n\n"
            "Here is the context:\n" + context
        )
        
        messages = [{"role": "system", "content": system_prompt}]
        
        # Add limited conversation memory (last 5 turns)
        messages.extend(self.conversation_memory[-10:])
        
        messages.append({"role": "user", "content": question})
        
        # Call Ollama
        try:
            response = requests.post(
                "http://localhost:11434/api/chat",
                json={
                    "model": "gemma3:latest",
                    "messages": messages,
                    "temperature": 0.2,
                    "stream": False
                },
                timeout=60
            )
            response.raise_for_status()
            answer_text = response.json().get("message", {}).get("content", "Error generating response.")
            
            # Update memory
            self.conversation_memory.append({"role": "user", "content": question})
            self.conversation_memory.append({"role": "assistant", "content": answer_text})
            # Keep only last 10 items (5 turns)
            if len(self.conversation_memory) > 10:
                self.conversation_memory = self.conversation_memory[-10:]
                
        except requests.exceptions.HTTPError as e:
            try:
                err_msg = e.response.json().get("error", e.response.text)
            except:
                err_msg = e.response.text
            answer_text = f"Ollama Error: {err_msg}"
            return {"answer": answer_text, "sources": sources}
        except Exception as e:
            answer_text = f"Failed to connect to Ollama. Ensure it is running at localhost:11434. Error: {str(e)}"
            return {"answer": answer_text, "sources": sources}
            
        unique_sources = []
        seen = set()
        for src in sources:
            key = f"{src['filename']}::{src['page_number']}"
            if key not in seen:
                seen.add(key)
                unique_sources.append(src)
                
        return {"answer": answer_text, "sources": unique_sources}
