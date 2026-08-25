import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const workbookPath = "deliverables/CNF_API_Request_Response_Specification_v1.8.xlsx";
const outDir = "sessions/2026-08-18-runtime-certification/workbook";
await fs.mkdir(outDir, { recursive: true });

const input = await FileBlob.load(workbookPath);
const workbook = await SpreadsheetFile.importXlsx(input);

const sheets = await workbook.inspect({
  kind: "sheet",
  include: "id,name",
  maxChars: 20000,
});
await fs.writeFile(`${outDir}/SHEETS.ndjson`, sheets.ndjson, "utf8");

const summary = await workbook.inspect({
  kind: "workbook,sheet,table",
  maxChars: 60000,
  tableMaxRows: 15,
  tableMaxCols: 20,
  tableMaxCellChars: 200,
});
await fs.writeFile(`${outDir}/WORKBOOK_SUMMARY.ndjson`, summary.ndjson, "utf8");

const apiMatches = await workbook.inspect({
  kind: "match",
  searchTerm: "API-|BAPI_|OData|SE37|payload|request|response",
  options: { useRegex: true, maxResults: 1000 },
  maxChars: 120000,
});
await fs.writeFile(`${outDir}/API_BAPI_MATCHES.ndjson`, apiMatches.ndjson, "utf8");

const sheetNames = [
  "Overview", "API-01 Submit MIGO", "API-02 Create DI",
  "API-03 Invoice Create", "API-04 Shipment Cost", "API-05 Stock Avail",
  "API-06 EWB Extension", "API-07 Invoice Corr", "API-08 STO Orders",
  "API-09 STO Deliveries", "API-10 STO Invoice", "API-11 Create STO PO",
  "API-12 Update DI Qty",
];
const cells = {};
for (const name of sheetNames) {
  const sheet = workbook.worksheets.getItem(name);
  const used = sheet.getUsedRange();
  cells[name] = used.values;
}
await fs.writeFile(`${outDir}/WORKBOOK_VALUES.json`, JSON.stringify(cells, null, 2), "utf8");

console.log(sheets.ndjson);
console.log(`INSPECTED|${workbookPath}|${outDir}`);
