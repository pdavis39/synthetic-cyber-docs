# Synthetic Cybersecurity Data Generator

A Python-based pipeline that uses a local LlamaCPP LLM + LangChain to synthesize realistic cybersecurity incident reports, writes them as `.txt` files with 30 DoD-style `xattr` metadata tags, and embeds & indexes them in a Chroma vector store.

---

## Features

- Zero-shot & few-shot prompting with LangChain  
- 5 customizable cyber-security templates  
- Realistic value pools (CVE IDs, products, APT groups, persons, orgs, geos) via Faker  
- Structured incident reports with 4 sections:
  1. Background & Context  
  2. Vulnerability & Exploit Details  
  3. Observed Impact & Affected Systems  
  4. Remediation & Recommendations  
- Extended attributes (`user.*`) on each file (30 synthetic DoD tags)  
- Sentence-Transformer embeddings  
- Chroma vector store indexing  

---

## Prerequisites

- Linux (or macOS) with a filesystem that supports `user_xattr`  
  - On local ext4/xfs: enabled by default  
  - On NFS: requires NFSv4.2+ with `xattr` export & mount options  
- Python 3.8+  
- A GGUF-format LLaMA-2 chat model on disk (e.g. `llama-2-7b-chat.Q4_K_M.gguf`)  

---

## Installation

1. Clone this repository  
   ```bash
   git clone https://github.com/your-org/synthetic-cyber-data.git
   cd synthetic-cyber-data
   ```

2. Create and activate a virtual environment  
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

3. Install Python dependencies  
   ```bash
   pip install --upgrade pip
   pip install \
     llama-cpp-python \
     langchain \
     langchain-community \
     sentence-transformers \
     chromadb \
     faker \
     xattr
   ```

---

## Configuration

- **Model path**  
  Edit `model_path` in the script to point at your local GGUF model:

  ```python
  model_path = "model/llama-2-7b-chat.Q4_K_M.gguf"
  ```

- **Output directory**  
  By default documents are written to `../../llm/synthetic_data`. Change:

  ```python
  output_dir = "<your/output/path>"
  ```

- **Number of documents**  
  Set `n_docs` to control how many synthetic docs to generate:

  ```python
  n_docs = 25
  ```

- **Chroma collection name**  
  By default it uses `cyber_synth2`. Change:

  ```python
  collection = chroma_client.create_collection(name="my_collection")
  ```

---

## Usage

Save the main notebook or script (e.g. `generate_synthetic.py`) and run:

```bash
python generate_synthetic.py
```

You should see console logs like:

```
✅ [1/25] wrote doc_0_abcdef01.txt
✅ [2/25] wrote doc_1_bcdef012.txt
…
🎉 Done – generated, tagged, and indexed 25 docs.
```

---

## Verifying Extended Attributes

Make sure your filesystem supports user‐namespace xattrs. Then inspect one file:

```bash
getfattr -d synthetic_data/doc_0_abcdef01.txt
```

Expected output:

```
# file: synthetic_data/doc_0_abcdef01.txt
user.classification="..."
user.classification_level="..."
…
user.audit_trail="..."
```

On macOS use:

```bash
xattr -l synthetic_data/doc_0_abcdef01.txt
```

---

## Customizing Templates & Values

- **Templates**  
  Located in the code as a list of `(template_string, slot2label)` tuples. Edit or add new templates.

- **Value Pools**  
  The `values` dict contains lists for each slot key (`"vuln"`, `"product"`, `"apt"`, etc.).  
  Replace or augment with your own realistic entries.

---

## Directory Structure

```
.
├── generate_synthetic.py   # Main Python script / notebook
├── model/                  # Place your .gguf LLaMA-2 model here
├── synthetic_data/         # Output .txt files + xattrs
└── README.md               # This file
```

---

## Troubleshooting

- **No xattrs persisted**  
  - Ensure `xattr` (`user_xattr`) is enabled on your FS or NFS export.  
  - Test locally on `/tmp`:  
    ```bash
    echo hi > /tmp/test.txt
    setfattr -n user.test -v hello /tmp/test.txt
    getfattr -d /tmp/test.txt
    ```
- **LLM returns empty**  
  - Increase `max_tokens` or lower `temperature`.  
  - Check your prompt examples for unescaped braces.

---


