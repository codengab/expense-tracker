// src/lib/utils/ocr.js
// Client-side only receipt scanning using Tesseract.js

let Tesseract = null;

async function getTesseract() {
  if (!Tesseract) {
    Tesseract = await import('tesseract.js');
  }
  return Tesseract;
}

export async function extractReceiptData(file, onProgress) {
  const { createWorker } = await getTesseract();

  const worker = await createWorker('ind+eng', 1, {
    logger: m => {
      if (onProgress && m.status === 'recognizing text') {
        onProgress(Math.round(m.progress * 100));
      }
    }
  });

  try {
    const imageUrl = URL.createObjectURL(file);
    const { data: { text } } = await worker.recognize(imageUrl);
    URL.revokeObjectURL(imageUrl);

    return parseReceiptText(text);
  } finally {
    await worker.terminate();
  }
}

export async function extractFromPdf(file, onProgress) {
  // Dynamically import PDF.js
  const pdfjsLib = await import('pdfjs-dist');
  pdfjsLib.GlobalWorkerOptions.workerSrc =
    'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';

  const arrayBuffer = await file.arrayBuffer();
  const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
  const page = await pdf.getPage(1);

  // Render to canvas
  const scale = 2;
  const viewport = page.getViewport({ scale });
  const canvas = document.createElement('canvas');
  canvas.width = viewport.width;
  canvas.height = viewport.height;

  const ctx = canvas.getContext('2d');
  await page.render({ canvasContext: ctx, viewport }).promise;

  // Convert canvas to blob
  const blob = await new Promise(resolve => canvas.toBlob(resolve, 'image/png'));
  return extractReceiptData(blob, onProgress);
}

function parseReceiptText(text) {
  const lines = text.split('\n').map(l => l.trim()).filter(Boolean);

  return {
    rawText: text,
    amount: extractAmount(text),
    date: extractDate(text),
    merchant: extractMerchant(lines)
  };
}

function extractAmount(text) {
  // Common patterns: "Total: Rp 150.000", "TOTAL 50000", "Rp. 75,000"
  const patterns = [
    /total\s*:?\s*(?:rp\.?\s*)?([0-9]{1,3}(?:[.,][0-9]{3})*)/i,
    /(?:jumlah|amount|bayar)\s*:?\s*(?:rp\.?\s*)?([0-9]{1,3}(?:[.,][0-9]{3})*)/i,
    /rp\.?\s*([0-9]{1,3}(?:[.,][0-9]{3})+)/i,
    /([0-9]{4,})/
  ];

  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match) {
      const raw = match[1].replace(/\./g, '').replace(/,/g, '');
      const num = parseInt(raw, 10);
      if (!isNaN(num) && num > 0) return num;
    }
  }
  return null;
}

function extractDate(text) {
  const patterns = [
    /(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})/,
    /(\d{1,2})\s+(jan|feb|mar|apr|mei|jun|jul|agt|sep|okt|nov|des)\s+(\d{4})/i
  ];

  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match) {
      try {
        const dateStr = match[0];
        const date = new Date(dateStr);
        if (!isNaN(date)) {
          return date.toISOString().split('T')[0];
        }
      } catch {}
    }
  }
  return new Date().toISOString().split('T')[0];
}

function extractMerchant(lines) {
  // Usually merchant name is in first 3 lines
  const candidates = lines.slice(0, 3).filter(l =>
    l.length > 3 &&
    !/^\d/.test(l) &&
    !/rp|total|nota|struk|receipt/i.test(l)
  );
  return candidates[0] || '';
}
