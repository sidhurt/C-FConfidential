import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const [file, ...sheetNames] = process.argv.slice(2);
const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(file));

if (sheetNames.length === 0) {
  const sheets = await workbook.inspect({ kind: "sheet", include: "id,name,range", maxChars: 12000 });
  console.log(sheets.ndjson);
} else {
  for (const sheetId of sheetNames) {
    console.log(`\n=== ${sheetId} ===`);
    const result = await workbook.inspect({
      kind: "table,region",
      sheetId,
      include: "range,values,formulas",
      maxChars: 45000,
      tableMaxRows: 120,
      tableMaxCols: 30,
      tableMaxCellChars: 500,
    });
    console.log(result.ndjson);
  }
}
