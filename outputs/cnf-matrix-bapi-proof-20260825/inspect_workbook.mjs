import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "C:/Users/sidmy/Downloads/CNF_API_Service_Implementation_Matrix.xlsx";
const outputDir = "C:/Users/sidmy/Downloads/shree-cement-cnf-agent-cowork-20260729T062834Z-1-001/shree-cement-cnf-agent-cowork/outputs/cnf-matrix-bapi-proof-20260825";

const input = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(input);

const overview = await workbook.inspect({
  kind: "workbook,sheet,table,region",
  maxChars: 14000,
  tableMaxRows: 24,
  tableMaxCols: 16,
  tableMaxCellChars: 240,
});
console.log(overview.ndjson);

const sheets = await workbook.inspect({ kind: "sheet", include: "id,name", maxChars: 4000 });
console.log(sheets.ndjson);

await fs.mkdir(outputDir, { recursive: true });
for (const sheet of workbook.worksheets.items) {
  const preview = await workbook.render({
    sheetName: sheet.name,
    autoCrop: "all",
    scale: 1.2,
    format: "png",
  });
  const safeName = sheet.name.replace(/[^a-z0-9_-]+/gi, "_");
  await fs.writeFile(`${outputDir}/before_${safeName}.png`, new Uint8Array(await preview.arrayBuffer()));
}
