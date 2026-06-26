Upload
File upload — returns public URLs for use in other APIs



POST
/api/upload
Upload one or more images


Upload images to the server. Returns public URLs that you then pass into:

POST /api/jobs/:id/images
POST /api/reports/:id/images
Accepted types: JPEG, PNG, WebP — max 10MB each, max 20 files per request.

Parameters
Try it out
Name	Description
entity_type
string
(query)
Optional — for record-keeping only

Available values : job, report


--
entity_id
string
(query)
Optional — e.g. JOB-0001

entity_id
Request body

multipart/form-data
images *
array<string>
One or more image files (JPEG, PNG, WebP)

Responses
Code	Description	Links
201	
Files uploaded successfully

No links
400	
No files, invalid type, or file too large

No links

POST
/api/upload/technical-reports
Upload technical report documents (PDF, Word, images)


Upload one or more technical report files before creating the report. No report ID is needed at this stage.

Typical flow:

Call POST /api/upload/technical-reports with your files (multipart).
Take the file_name + file_url from the response.
Pass them in the technical_reports[] array when calling POST /api/reports.
Accepted types: PDF, JPEG, PNG, WebP, DOC, DOCX Limits: Max 20MB each, max 10 files per request.

Parameters
Try it out
No parameters

Request body

multipart/form-data
files *
array<string>
One or more document files (PDF, Word, images)

Responses
Code	Description	Links
201	
Files uploaded successfully

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string",
  "note": "Pass these objects in the technical_reports[] array when calling POST /api/reports.",
  "data": [
    {
      "id": 0,
      "file_name": "inspection_report.pdf",
      "stored_name": "string",
      "file_url": "https://yourserver.com/uploads/1714012345678_inspection_report.pdf",
      "mime_type": "application/pdf",
      "file_size_bytes": 0,
      "uploaded_at": "2026-06-26T07:11:11.453Z"
    }
  ]
}
No links
400	
No files, invalid type, or file too large

No links

POST
/api/upload/document-links
Upload document(s) for upload_document_link[]


"Normal" document upload. Upload one or more documents and get back URLs to place in the upload_document_link[] array when calling POST /api/reports, or POST to /api/reports/:id/documents.

Accepted types: PDF, JPEG, PNG, WebP, DOC, DOCX Limits: Max 20MB each, max 10 files per request.

Parameters
Try it out
No parameters

Request body

multipart/form-data
files *
array<string>
One or more document files (PDF, Word, images)

Responses
Code	Description	Links
201	
Files uploaded successfully

No links
400	
No files, invalid type, or file too large

No links

POST
/api/upload/technician-documents
Upload technician document files (PDF, JPG, PNG)


Upload one or more technician document files before attaching them. No technician ID is needed at this stage.

Typical flow:

Call POST /api/upload/technician-documents with your files (multipart).
Take the file_name + file_url from the response.
Pass them when calling POST /api/technicians/:id/documents.
Accepted types: PDF, JPEG, PNG, WebP, DOC, DOCX Limits: Max 20MB each, max 10 files per request.

Parameters
Try it out
Name	Description
document_type
string
(query)
Optional — pre-tag the upload with a document type

Available values : Aadhaar Card, Technician Photo, WC Policy, Medical Insurance Policy, Other


--
document_name
string
(query)
Optional — user-facing label (defaults to original filename)

document_name
expiry_date
string($date)
(query)
Optional — document expiry date (e.g. 2026-12-31)

expiry_date
notes
string
(query)
Optional — notes about the document

notes
Request body

multipart/form-data
files *
array<string>
One or more document files (PDF, JPG, PNG, WebP, DOC, DOCX)

Responses
Code	Description	Links
201	
Files uploaded successfully

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string",
  "note": "Use file_name + file_url when calling POST /api/technicians/:id/documents.",
  "data": [
    {
      "id": 0,
      "file_name": "aadhaar_front.jpg",
      "stored_name": "string",
      "file_url": "https://apivdti.asynk.in/uploads/1714012345678_aadhaar_front.jpg",
      "mime_type": "image/jpeg",
      "file_size_bytes": 0,
      "uploaded_at": "2026-06-26T07:11:11.473Z",
      "document_type": "Aadhaar Card",
      "document_name": "string",
      "expiry_date": "2026-06-26",
      "notes": "string"
    }
  ]
}
No links
400	
No files, invalid type, or file too large

No links

DELETE
/api/upload/{id}
Delete an uploaded file by ID