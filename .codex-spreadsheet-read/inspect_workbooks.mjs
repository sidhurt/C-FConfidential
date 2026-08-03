import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const files = process.argv.slice(2);

for (const file of files) {
  const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(file));
  console.log(`\n=== ${file} ===`);
  const summary = await workbook.inspect({
    kind: "workbook,sheet,table,region",
    include: "id,name,range,values,formulas",
    maxChars: 30000,
    tableMaxRows: 80,
    tableMaxCols: 20,
    tableMaxCellChars: 300,
  });
  console.log(summary.ndjson);
}
