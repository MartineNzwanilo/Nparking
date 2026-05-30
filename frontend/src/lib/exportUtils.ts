// ─── CSV Export ──────────────────────────────────────────────────────────────
export function exportCSV(filename: string, rows: Record<string, any>[]) {
  if (!rows.length) return;
  const headers = Object.keys(rows[0]);
  const csv = [
    headers.join(','),
    ...rows.map(row =>
      headers.map(h => {
        const val = row[h] ?? '';
        const str = String(val);
        return str.includes(',') || str.includes('"') ? `"${str.replace(/"/g, '""')}"` : str;
      }).join(',')
    )
  ].join('\n');

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `${filename}.csv`;
  link.click();
  URL.revokeObjectURL(link.href);
}

// ─── PDF Export ──────────────────────────────────────────────────────────────
export async function exportPDF(
  filename: string,
  title: string,
  subtitle: string,
  rows: Record<string, any>[],
  summary?: Record<string, any>
) {
  if (!rows.length) return;

  const { default: jsPDF } = await import('jspdf');
  const { default: autoTable } = await import('jspdf-autotable');

  const doc = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'a4' });

  // Header bar
  doc.setFillColor(4, 169, 245);
  doc.rect(0, 0, 297, 22, 'F');

  // Title
  doc.setTextColor(255, 255, 255);
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.text('LOCOMOTORS PARKING', 14, 10);

  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  doc.text(title.toUpperCase(), 14, 17);

  // Date on right
  doc.setFontSize(8);
  doc.text(`Generated: ${new Date().toLocaleString()}`, 297 - 14, 10, { align: 'right' });
  doc.text(subtitle, 297 - 14, 17, { align: 'right' });

  // Summary bar
  if (summary) {
    let y = 28;
    doc.setTextColor(60, 60, 60);
    doc.setFontSize(8);
    doc.setFont('helvetica', 'bold');
    const summaryEntries = Object.entries(summary);
    summaryEntries.forEach(([key, val], i) => {
      const x = 14 + i * 60;
      doc.setTextColor(120, 120, 120);
      doc.text(key.replace(/([A-Z])/g, ' $1').toUpperCase(), x, y);
      doc.setTextColor(30, 30, 30);
      doc.setFontSize(10);
      doc.text(String(val), x, y + 5);
      doc.setFontSize(8);
    });
    y += 14;

    // Table
    const headers = Object.keys(rows[0]);
    const tableRows = rows.map(r => headers.map(h => String(r[h] ?? '—')));

    autoTable(doc, {
      startY: y,
      head: [headers.map(h => h.replace(/([A-Z])/g, ' $1').toUpperCase())],
      body: tableRows,
      styles: { fontSize: 7, cellPadding: 2 },
      headStyles: { fillColor: [4, 169, 245], textColor: 255, fontStyle: 'bold', fontSize: 7 },
      alternateRowStyles: { fillColor: [247, 250, 252] },
      margin: { left: 14, right: 14 },
    });
  } else {
    const headers = Object.keys(rows[0]);
    const tableRows = rows.map(r => headers.map(h => String(r[h] ?? '—')));
    autoTable(doc, {
      startY: 28,
      head: [headers.map(h => h.replace(/([A-Z])/g, ' $1').toUpperCase())],
      body: tableRows,
      styles: { fontSize: 7, cellPadding: 2 },
      headStyles: { fillColor: [4, 169, 245], textColor: 255, fontStyle: 'bold', fontSize: 7 },
      alternateRowStyles: { fillColor: [247, 250, 252] },
      margin: { left: 14, right: 14 },
    });
  }

  // Page numbers
  const pageCount = (doc as any).internal.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.setFontSize(7);
    doc.setTextColor(160, 160, 160);
    doc.text(`Page ${i} of ${pageCount}`, 297 - 14, 205, { align: 'right' });
  }

  doc.save(`${filename}.pdf`);
}
