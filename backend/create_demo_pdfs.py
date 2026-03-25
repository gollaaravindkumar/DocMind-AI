from fpdf import FPDF
import os

def create_pdf(filename, title, content):
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", size=16, style='B')
    pdf.cell(200, 10, txt=title, ln=1, align='C')
    pdf.ln(10)
    pdf.set_font("Arial", size=12)
    
    # Handle multi-line text and encoding
    safe_content = content.encode('latin-1', 'replace').decode('latin-1')
    pdf.multi_cell(0, 10, txt=safe_content)
    
    pdf.output(filename)

os.makedirs("demo_datasets", exist_ok=True)

# 1. arxiv_ml_paper_1.pdf - attention mechanism
create_pdf(
    "demo_datasets/arxiv_ml_paper_1.pdf",
    "Attention Is All You Need",
    "Abstract: The dominant sequence transduction models are based on complex recurrent or convolutional neural networks that include an encoder and a decoder. The best performing models also connect the encoder and decoder through an attention mechanism. We propose a new simple network architecture, the Transformer, based solely on attention mechanisms, dispensing with recurrence and convolutions entirely. The attention mechanism allows the model to selectively focus on relevant parts of the input sequence when producing an output, rather than relying on a fixed-length context vector."
)

# 2. arxiv_ml_paper_2.pdf - RAG
create_pdf(
    "demo_datasets/arxiv_ml_paper_2.pdf",
    "Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks",
    "Abstract: Large pre-trained language models have been shown to store factual knowledge in their parameters, and achieve state-of-the-art results when fine-tuned on downstream NLP tasks. However, their ability to access and precisely manipulate knowledge is still limited. We explore Retrieval-Augmented Generation (RAG), a general-purpose fine-tuning recipe for retrieval-augmented generation. RAG models combine parametric memory with non-parametric memory. The non-parametric memory is a dense vector index of Wikipedia or other document corpora, accessed with a pre-trained neural retriever."
)

# 3. company_hr_policy.pdf
create_pdf(
    "demo_datasets/company_hr_policy.pdf",
    "Company Employee Leave Policy 2024",
    "1. Introduction\nThis policy outlines the leave benefits provided to all full-time employees.\n\n2. Sick Leave\nAll full-time employees are entitled to 12 paid sick days per calendar year. Sick days can be used for personal illness, medical appointments, or caring for a sick family member. Unused sick days do not roll over to the next year.\n\n3. Annual Leave / Vacation\nEmployees accrue 20 days of paid vacation per year.\n\n4. Bereavement Leave\nEmployees are allowed up to 5 days of paid leave in the event of the death of an immediate family member."
)

# 4. enron_sample.pdf
create_pdf(
    "demo_datasets/enron_sample.pdf",
    "Enron Internal Communications - Q3 Directives",
    "From: Ken Lay\nTo: Executive Management Team\nDate: September 5, 2001\nSubject: Q3 Targets and Energy Prices\n\nTeam,\nAs we approach the end of the third quarter, I want to emphasize our primary goals. Our Q3 targets are highly aggressive this year. Management expects every division to reduce operational costs by 15% compared to Q2. \n\nRegarding energy prices, the CEO has explicitly stated that 'we expect energy prices in the California market to remain highly volatile throughout the rest of the year, potentially peaking in late November'. Please adjust your trading models accordingly to capitalize on these wide spreads.\n\nIf we miss these Q3 targets, bonuses will be significantly impacted."
)

print("Demo PDFs generated successfully in 'demo_datasets' folder.")
