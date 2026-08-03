import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const workspace = String.raw`C:\Users\sidmy\Downloads\shree-cement-cnf-agent-cowork-20260729T062834Z-1-001\shree-cement-cnf-agent-cowork`;
const previewRoot = String.raw`C:\Users\sidmy\.codex\visualizations\2026\07\30\019fb174-4ea7-75e0-89cd-d7d30f27c96c\latest_workbooks`;
const inputs = [
  path.join(workspace, "deliverables", "CNF_API_Classification.xlsx"),
  path.join(workspace, "deliverables", "CNF_Delivery_Planning.xlsx"),
];

await fs.mkdir(previewRoot, { recursive: true });
const all = [];

for (const inputPath of inputs) {
  const input = await FileBlob.load(inputPath);
  const workbook = await SpreadsheetFile.importXlsx(input);
  const bookName = path.basename(inputPath, ".xlsx");
  const bookDir = path.join(previewRoot, bookName);
  await fs.mkdir(bookDir, { recursive: true });

  const summary = await workbook.inspect({
    kind: "workbook,sheet,table,definedName,drawing",
    maxChars: 12000,
    tableMaxRows: 12,
    tableMaxCols: 16,
    tableMaxCellChars: 160,
  });
  await fs.writeFile(path.join(bookDir, "summary.ndjson"), summary.ndjson, "utf8");

  const errorScan = await workbook.inspect({
    kind: "match",
    searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
    options: { useRegex: true, maxResults: 300 },
    summary: "formula error scan",
  });
  await fs.writeFile(path.join(bookDir, "formula_errors.ndjson"), errorScan.ndjson, "utf8");

  const sheets = [];
  for (const sheet of workbook.worksheets.items) {
    const used = sheet.getUsedRange();
    const values = used ? used.values : [];
    const formulas = used ? used.formulas : [];
    const sheetRecord = {
      name: sheet.name,
      rowCount: Array.isArray(values) ? values.length : 0,
      colCount: Array.isArray(values) && values.length ? Math.max(...values.map((r) => r.length)) : 0,
      values,
      formulas,
    };
    sheets.push(sheetRecord);
    const preview = await workbook.render({
      sheetName: sheet.name,
      autoCrop: "all",
      scale: 1.25,
      format: "png",
    });
    await fs.writeFile(
      path.join(bookDir, `${sheet.name.replace(/[<>:"/\\|?*]/g, "_")}.png`),
      new Uint8Array(await preview.arrayBuffer()),
    );
  }

  await fs.writeFile(path.join(bookDir, "values.json"), JSON.stringify(sheets, null, 2), "utf8");
  all.push({
    workbook: bookName,
    sheets: sheets.map((s) => ({ name: s.name, rows: s.rowCount, cols: s.colCount })),
    summaryPath: path.join(bookDir, "summary.ndjson"),
    valuesPath: path.join(bookDir, "values.json"),
  });
}

console.log(JSON.stringify(all, null, 2));
