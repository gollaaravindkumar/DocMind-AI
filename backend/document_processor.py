import fitz  # PyMuPDF
from langchain_text_splitters import RecursiveCharacterTextSplitter

def process_pdf(file_path: str, filename: str):
    """
    Extracts text page by page from a PDF and splits into chunks.
    """
    doc = fitz.open(file_path)
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=500,
        chunk_overlap=50,
        separators=["\n\n", "\n", " ", ""]
    )
    
    chunks = []
    
    for page_num in range(len(doc)):
        page = doc[page_num]
        text = page.get_text()
        
        if text.strip():
            page_chunks = text_splitter.split_text(text)
            for chunk_text in page_chunks:
                chunks.append({
                    "text": chunk_text,
                    "metadata": {
                        "filename": filename,
                        "page_number": page_num + 1
                    }
                })
                
    doc.close()
    return chunks
