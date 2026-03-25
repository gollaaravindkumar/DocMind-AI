import os
import json
import numpy as np
import faiss
from sentence_transformers import SentenceTransformer

class VectorStore:
    def __init__(self, index_path="faiss_index.bin", metadata_path="metadata.json"):
        self.index_path = index_path
        self.metadata_path = metadata_path
        
        # sentence-transformers/all-MiniLM-L6-v2 converts chunks to 384-dim vectors
        self.encoder = SentenceTransformer("all-MiniLM-L6-v2")
        self.dimension = self.encoder.get_sentence_embedding_dimension()
        
        self.index = faiss.IndexFlatIP(self.dimension)
        self.metadata = []
        
        self.load()

    def load(self):
        if os.path.exists(self.index_path):
            self.index = faiss.read_index(self.index_path)
        if os.path.exists(self.metadata_path):
            with open(self.metadata_path, 'r', encoding='utf-8') as f:
                self.metadata = json.load(f)
                
    def save(self):
        faiss.write_index(self.index, self.index_path)
        with open(self.metadata_path, 'w', encoding='utf-8') as f:
            json.dump(self.metadata, f, ensure_ascii=False, indent=2)
            
    def add_chunks(self, chunks):
        if not chunks:
            return
            
        texts = [chunk["text"] for chunk in chunks]
        embeddings = self.encoder.encode(texts)
        faiss.normalize_L2(embeddings)
        self.index.add(embeddings)
        
        for chunk in chunks:
            self.metadata.append(chunk)
            
        self.save()

    def search(self, query: str, top_k: int = 4):
        if self.index.ntotal == 0:
            return []
            
        query_vector = self.encoder.encode([query])
        faiss.normalize_L2(query_vector)
        distances, indices = self.index.search(query_vector, top_k)
        
        results = []
        for i in range(len(indices[0])):
            idx = indices[0][i]
            if idx != -1:
                chunk = self.metadata[idx].copy()
                chunk["score"] = float(distances[0][i])
                chunk["chunk_id"] = int(idx)
                results.append(chunk)
        return results

    def remove_document(self, filename: str):
        remaining_chunks = [chunk for chunk in self.metadata if chunk["metadata"].get("filename") != filename]
        
        self.index = faiss.IndexFlatIP(self.dimension)
        self.metadata = []
        if remaining_chunks:
            self.add_chunks(remaining_chunks)
        else:
            self.save()

    def reset(self):
        self.index = faiss.IndexFlatIP(self.dimension)
        self.metadata = []
        self.save()
