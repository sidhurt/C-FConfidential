import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "C:/Users/sidmy/Downloads/CNF_API_Service_Implementation_Matrix.xlsx";
const outputDir = "C:/Users/sidmy/Downloads/shree-cement-cnf-agent-cowork-20260729T062834Z-1-001/shree-cement-cnf-agent-cowork/outputs/cnf-matrix-bapi-proof-20260825";
const outputPath = `${outputDir}/CNF_API_Service_Implementation_Matrix.xlsx`;

const input = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(input);
const sheet = workbook.worksheets.getItem("API Matrix");

sheet.getRange("A2").values = [[
  "Simple current-state view based on v1.9 and runtime/BAPI evidence through 25 Aug 2026",
]];

sheet.getRange("D5").values = [[
  "BAPI_GOODSMVT_CREATE is the standard BAPI equivalent. The selected implementation remains API_MATERIAL_DOCUMENT_SRV; its internal call path has not been traced.",
]];

sheet.getRange("E5").values = [[
  "Runtime-certified in QS4/700 on 25 Aug 2026. Standard OData created material document 5007138616/2026 with PO 5600084238/00010 and delivery 9004953150/000010. OData readback, MSEG and predecessor consumption confirmed the posting. Batch-split receipts remain untested.",
]];

sheet.getRange("G5").values = [[
  "Use the standard service. Require GoodsMovementRefDocType B and send both PO/item and delivery/item. Read the live delivery structure before posting batch-managed materials. Add duplicate handling and reversal after the remaining tests.",
]];

sheet.getRange("H5:L5").values = [[
  "GM code 01; RefDocType B; movement 101; material 17035056; 1022/FKGU; 4 EA; PO 5600084238/00010; delivery 9004953150/000010",
  "/sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/A_MaterialDocumentHeader?sap-client=700",
  "5007138616 / 2026",
  "Certified — non-batch STO receipt proven; batch split open",
  new Date("2026-08-25T00:00:00+05:30"),
]];

sheet.getRange("D6").values = [[
  "BAPI_OUTB_DELIVERY_CREATE_STO is called internally for the STO path. Proven on 25 Aug 2026 by an external breakpoint during the standard OData POST. BAPI_OUTB_DELIVERY_CREATE_SLS remains the expected sales-order path and is not yet traced.",
]];

sheet.getRange("E6").values = [[
  "Proven end to end in QS4: OData created delivery 9004953174 and LIKP/LIPS confirmed persistence. A separate debugger run proved that the standard service calls BAPI_OUTB_DELIVERY_CREATE_STO for STO creation. Trade and Non-trade remain untraced.",
]];

sheet.getRange("G6").values = [[
  "Reuse the proven standard deep insert; no custom delivery-creation wrapper is required. Test Trade and Non-trade sales-order predecessors, then add only CPI/T2 replay, error mapping and response shaping.",
]];

sheet.getRange("K4").values = [["Status"]];
sheet.getRange("H6:L6").values = [[
  "ShippingPoint 1002; STO/item 5600084209/000010; quantity 1 TO",
  "/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/A_OutbDeliveryHeader?sap-client=700",
  "9004953174",
  "Complete — STO OData and internal BAPI path proven",
  new Date("2026-08-25T00:00:00+05:30"),
]];

sheet.getRange("D6:L6").format.wrapText = true;
sheet.getRange("D6:L6").format.verticalAlignment = "top";
sheet.getRange("D5:L5").format.wrapText = true;
sheet.getRange("D5:L5").format.verticalAlignment = "top";
sheet.getRange("L5").format.numberFormat = "dd mmm yyyy";
sheet.getRange("L6").format.numberFormat = "dd mmm yyyy";
sheet.getRange("H:H").format.columnWidth = 24;
sheet.getRange("I:I").format.columnWidth = 38;
sheet.getRange("J:J").format.columnWidth = 18;
sheet.getRange("K:K").format.columnWidth = 23;
sheet.getRange("L:L").format.columnWidth = 15;
sheet.getRange("5:5").format.rowHeight = 115;
sheet.getRange("6:6").format.rowHeight = 105;

await fs.mkdir(outputDir, { recursive: true });

const preview = await workbook.render({
  sheetName: "API Matrix",
  autoCrop: "all",
  scale: 1.2,
  format: "png",
});
await fs.writeFile(`${outputDir}/after_API_Matrix.png`, new Uint8Array(await preview.arrayBuffer()));

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);

const check = await workbook.inspect({
  kind: "table",
  range: "API Matrix!A1:L16",
  include: "values,formulas",
  tableMaxRows: 16,
  tableMaxCols: 12,
  tableMaxCellChars: 260,
  maxChars: 18000,
});
console.log(check.ndjson);

const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 300 },
  summary: "final formula error scan",
});
console.log(errors.ndjson);
