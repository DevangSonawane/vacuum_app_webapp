Explore

Errors
Hide
 
Resolver error at paths./api/clients/{id}.get.responses.200.content.application/json.schema.properties.data.$ref
Could not resolve reference: Could not resolve pointer: /components/schemas/ClientDetailResponse does not exist in document
Resolver error at paths./api/dashboard.get.responses.200.content.application/json.schema.$ref
Could not resolve reference: Could not resolve pointer: /components/schemas/DashboardResponse does not exist in document
Resolver error at paths./api/technicians/login.post.responses.200.content.application/json.schema.$ref
Could not resolve reference: Could not resolve pointer: /components/schemas/TechnicianLoginResponse does not exist in document
 
VDTI Service Hub API
 1.0.0 
OAS 3.0
VDTI Service Hub REST API

Built with Node.js + Express + PostgreSQL

Authentication

Use the Authorize button (top right) and enter your JWT token as: Bearer YOUR_TOKEN_HERE

File Uploads

POST /api/upload — Upload image(s) → get back public file_url
Use that file_url in POST /api/jobs/:id/images or POST /api/reports/:id/images
Base URLs

Production: https://vaccumapi-o4ol.onrender.com/
Local: http://localhost:3000
Servers


Authorize
User Management
User list, update, and delete APIs (Admin & authorized roles)



GET
/api/users
Get list of all users with pagination and filters


Parameters
Try it out
Name	Description
page
integer
(query)
Page number
Default value : 1


limit
integer
(query)
Number of users per page (max 100)
Default value : 10


role
string
(query)
Filter users by role
Available values : admin, engineer, labour, manager


search
string
(query)
Search by first name, last name, or email

Responses
Code	Description	Links
200	
List of users with pagination metadata
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "data": [
    {
      "id": 0,
      "first_name": "string",
      "last_name": "string",
      "email": "string",
      "phone_number": "string",
      "role": "admin",
      "is_active": true,
      "last_login_at": "2026-05-27T10:33:25.743Z",
      "created_at": "2026-05-27T10:33:25.743Z",
      "updated_at": "2026-05-27T10:33:25.743Z"
    }
  ],
  "pagination": {
    "total": 50,
    "page": 1,
    "limit": 10,
    "total_pages": 5
  }
}
No links
401	
Unauthorized
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
403	
Forbidden - insufficient role
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

PUT
/api/users/{id}
Update a user by ID


Admin can update all fields including role and is_active.
Other users can only update their own first_name, last_name, and phone_number.
Parameters
Try it out
Name	Description
id *
integer
(path)
User ID to update

Request body

Example Value
Schema
{
  "first_name": "string",
  "last_name": "string",
  "phone_number": "string",
  "role": "admin",
  "is_active": true
}
Responses
Code	Description	Links
200	
User updated successfully
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string",
  "data": {
    "id": 0,
    "first_name": "string",
    "last_name": "string",
    "email": "string",
    "phone_number": "string",
    "role": "admin",
    "is_active": true,
    "last_login_at": "2026-05-27T10:33:25.752Z",
    "created_at": "2026-05-27T10:33:25.752Z",
    "updated_at": "2026-05-27T10:33:25.752Z"
  }
}
No links
400	
Validation error
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
403	
Forbidden
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
404	
User not found
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
409	
Phone number already in use
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

DELETE
/api/users/{id}
Deactivate (soft delete) a user by ID


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


entity_id
string
(query)
Optional — e.g. JOB-0001

Request body

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

files *
array<string>
One or more document files (PDF, Word, images)
Responses
Code	Description	Links
201	
Files uploaded successfully
Media type

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
      "uploaded_at": "2026-05-27T10:33:25.767Z"
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


Deletes the file from disk AND removes the database record.

Parameters
Try it out
Name	Description
id *
integer
(path)

Responses
Code	Description	Links
200	
File deleted
No links
404	
Upload not found
No links
Technicians
Technician management and login



POST
/api/technicians/login
Technician login (email or phone + password)

Technicians log in using the user account linked to their technician profile. A user account with role = technician must exist (created when the technician profile was added with a password).

Parameters
Try it out
No parameters
Request body

Examples: 
Example Value
Schema
{
  "email": "ravi@ism.com",
  "password": "password123"
}
Responses
Code	Description	Links
200	
Login successful
Media type

Controls Accept header.
Example Value
Schema
"string"
No links
400	
Missing credentials
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
401	
Invalid credentials
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
403	
Account inactive
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

GET
/api/technicians
List all technicians with optional filters


Parameters
Try it out
Name	Description
page
integer
(query)
Default value : 1

limit
integer
(query)
Default value : 50

status
string
(query)
Available values : Active, On Leave, Inactive

specialization
string
(query)
Filter by specialization (partial match)

search
string
(query)
Search by name or specialization

Responses
Code	Description	Links
200	
List of technicians
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "data": [
    {
      "id": 0,
      "user_id": 0,
      "name": "Ravi Kumar",
      "email": "string",
      "phone": "string",
      "specialization": "HVAC",
      "status": "Active",
      "join_date": "2022-03-15",
      "jobs_completed": 0,
      "rating": 0,
      "avatar": "RK",
      "created_at": "2026-05-27T10:33:25.789Z",
      "updated_at": "2026-05-27T10:33:25.789Z"
    }
  ],
  "pagination": {
    "total": 0,
    "page": 0,
    "limit": 0,
    "total_pages": 0
  }
}
No links
401	
Unauthorized
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

POST
/api/technicians
Add a new technician


Creates a technician profile. If password is provided, a linked users account with role = technician is also created so the technician can log in via /api/technicians/login.

If a users row with role = technician already exists for the given email/phone, it will be linked automatically without creating a duplicate user.

Parameters
Try it out
No parameters
Request body

Examples: 
Example Value
Schema
{
  "name": "Ravi Kumar",
  "email": "ravi@ism.com",
  "phone": "9876543210",
  "specialization": "HVAC",
  "status": "Active",
  "join_date": "2024-01-20",
  "password": "techpass123"
}
Responses
Code	Description	Links
201	
Technician added successfully
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string",
  "data": {
    "id": 0,
    "user_id": 0,
    "name": "Ravi Kumar",
    "email": "string",
    "phone": "string",
    "specialization": "HVAC",
    "status": "Active",
    "join_date": "2022-03-15",
    "jobs_completed": 0,
    "rating": 0,
    "avatar": "RK",
    "created_at": "2026-05-27T10:33:25.800Z",
    "updated_at": "2026-05-27T10:33:25.800Z"
  }
}
No links
400	
Validation error
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
409	
Email or phone already in use
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

GET
/api/technicians/{id}
Get a single technician with recent job history



PUT
/api/technicians/{id}
Update a technician's profile


Parameters
Try it out
Name	Description
id *
integer
(path)

Request body

Example Value
Schema
{
  "name": "string",
  "email": "user@example.com",
  "phone": "string",
  "specialization": "string",
  "status": "Active",
  "join_date": "2022-03-15"
}
Responses
Code	Description	Links
200	
Technician updated
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string",
  "data": {
    "id": 0,
    "user_id": 0,
    "name": "Ravi Kumar",
    "email": "string",
    "phone": "string",
    "specialization": "HVAC",
    "status": "Active",
    "join_date": "2022-03-15",
    "jobs_completed": 0,
    "rating": 0,
    "avatar": "RK",
    "created_at": "2026-05-27T10:33:25.808Z",
    "updated_at": "2026-05-27T10:33:25.808Z"
  }
}
No links
400	
Validation error
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
404	
Not found
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

DELETE
/api/technicians/{id}
Delete a technician (admin or manager only)


Cannot delete if the technician has open (non-closed) jobs.

Parameters
Try it out
Name	Description
id *
integer
(path)

Responses
Code	Description	Links
200	
Technician deleted
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string"
}
No links
404	
Not found
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
409	
Technician has open jobs
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "TECHNICIAN_HAS_OPEN_JOBS",
  "message": "string",
  "details": {
    "open_job_ids": [
      "JOB-0001",
      "JOB-0003"
    ]
  }
}
No links
Reports
AMC Service Report management



GET
/api/reports
List all service reports with optional filters


Parameters
Try it out
Name	Description
page
integer
(query)
Default value : 1

limit
integer
(query)
Default value : 50

status
string
(query)
Available values : Pending, Approved, Rejected

technician_id
integer
(query)

job_id
string
(query)
e.g. JOB-0001

client_id
integer
(query)

po_number
string
(query)
Filter by PO Number

from_date
string($date)
(query)

to_date
string($date)
(query)

Responses
Code	Description	Links
200	
List of reports
No links

POST
/api/reports
Submit a new AMC service report (Italvacuum Pump)


Submits a new AMC Service Report matching the PDF form layout. Status is always Pending on creation.

PDF Pages mapped to API fields:

Page 1 – Client info block (company_name, location, contact_person, model_serial_installation, operating_hours_per_day, application_process_description) + checklist_items[]
Page 2 – issue_observations[] (Issue–Observation–Impact matrix)
Page 3 – remarks (free-text)
Page 4 – mandatory_spares[] + signature fields (vdt_representative_name, client_representative_name)
technical_reports flow (2 steps):

Upload files via POST /api/upload/technical-reports (multipart) — get back URLs.
Pass those URLs in the technical_reports array here.
po_number validation: If provided, must match an existing AMC contract.

Email: A full report HTML email is automatically sent to client_email on submit.

Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "job_id": "JOB-0001",
  "title": "Quarterly AMC Service — Italvacuum Pump",
  "technician_id": 3,
  "company_name": "Acme Industries Pvt Ltd",
  "location": "Plant Room B, Floor 2",
  "contact_person": "Rajesh Mehta",
  "model_serial_installation": "ITPUMP-V2 / SN-20034 / 2021",
  "operating_hours_per_day": "18 hrs",
  "application_process_description": "Vacuum drying of pharmaceutical granules",
  "checklist_items": [
    {
      "sr": 1,
      "description": "Check the oil level in the oil reserves.",
      "status": "OK"
    }
  ],
  "issue_observations": [
    {
      "sr": 1,
      "issue": "Low Vaccum",
      "observation": "Valve damage (chock up)",
      "impact_on_pump": "Overheat",
      "severity": "Med",
      "recommended_spares": "Valve set"
    }
  ],
  "remarks": "Pump was running with unusual noise at startup.",
  "mandatory_spares": [
    {
      "spare_name": "Complete set of Gaskets",
      "pump_model": "ITPUMP-V2",
      "total_to_order": "2"
    }
  ],
  "vdt_representative_name": "Suresh Patil",
  "client_representative_name": "Rajesh Mehta",
  "po_number": "PO-2025-001",
  "serial_no": "VCP-2023-7842",
  "findings": "string",
  "recommendations": "string",
  "comments": "string",
  "client_id": 0,
  "client_name": "string",
  "client_email": "facilities@acme.com",
  "technical_reports": [
    {
      "file_name": "string",
      "file_url": "string",
      "mime_type": "string",
      "file_size_bytes": 0
    }
  ]
}
Responses
Code	Description	Links
201	
Report created, email sent to client
No links
400	
Validation error
No links

GET
/api/reports/{id}
Get a single report with all related data


Returns the full report including checklist_items, issue_observations, mandatory_spares, images, and technical_reports.

Parameters
Try it out
Name	Description
id *
string
(path)
Example : RPT-0001

Responses
Code	Description	Links
200	
Full report object
No links
404	
Report not found
No links

GET
/api/reports/{id}/pdf
Generate and download the AMC Service Report as a PDF


Generates the full 4-page AMC Service Report PDF matching the official layout (Vacuum Drying Technology India LLP letterhead, checklist, issue matrix, mandatory spares, and signature block).

If puppeteer is installed, returns a real application/pdf file.
Otherwise falls back to text/html which can be printed to PDF from the browser.
Parameters
Try it out
Name	Description
id *
string
(path)
Example : RPT-0001

Responses
Code	Description	Links
200	
PDF file (or HTML fallback)
Media type

Controls Accept header.
Example Value
Schema
string
No links
404	
Report not found
No links

POST
/api/reports/{id}/share
Share the AMC Service Report to one or more email addresses


Sends the full AMC Service Report as a rich HTML email to the provided recipient(s). The email includes all report sections: client info, checklist, issue matrix, mandatory spares, and links to any attached technical documents.

Useful for sending the report to the client, a manager, or any third party after it has been created.

Parameters
Try it out
Name	Description
id *
string
(path)
Example : RPT-0001

Request body

Example Value
Schema
{
  "to": "client@example.com",
  "subject": "Your AMC Service Report RPT-0001 — Quarterly Inspection",
  "message": "Please find your service report attached. Let us know if you have any questions."
}
Responses
Code	Description	Links
200	
Report shared successfully
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string",
  "recipients": [
    "string"
  ]
}
No links
400	
Missing or invalid email address
No links
404	
Report not found
No links

PATCH
/api/reports/{id}/status
Approve or reject a report (admin only)


Only Pending reports can be reviewed. Status cannot be changed again once set.

Parameters
Try it out
Name	Description
id *
string
(path)
Example : RPT-0001

Request body

Example Value
Schema
{
  "status": "Approved",
  "rejection_note": "string"
}
Responses
Code	Description	Links
200	
Report status updated
No links
400	
Already reviewed or invalid status
No links
404	
Report not found
No links

POST
/api/reports/{id}/images
Add image(s) to a report


Pass a single object or an array of objects with file_name and file_url.

Parameters
Try it out
Name	Description
id *
string
(path)
Example : RPT-0001

Request body

Example Value
Schema
{
  "file_name": "string",
  "file_url": "string",
  "mime_type": "image/jpeg",
  "file_size_bytes": 0
}
Responses
Code	Description	Links
201	
Image(s) added
No links
400	
Validation error or max images exceeded
No links
404	
Report not found
No links
Notifications
In-app notification history (persisted WebSocket events)



GET
/api/notifications
Get notifications for the current user


Returns notifications targeted at this user (by user_id or role). These are the same events pushed over WebSocket, persisted so they survive page refreshes.

Parameters
Try it out
Name	Description
limit
integer
(query)
Default value : 30

unread
boolean
(query)
If true, return only unread notifications

Responses
Code	Description	Links
200	
List of notifications
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "unread_count": 3,
  "data": [
    {
      "id": 0,
      "event": "job_raised",
      "title": "New Job Raised",
      "message": "string",
      "entity_type": "job",
      "entity_id": "JOB-0001",
      "is_read": true,
      "created_at": "2026-05-27T10:33:25.858Z"
    }
  ]
}
No links

DELETE
/api/notifications
Clear all notifications for the current user


Parameters
Try it out
No parameters
Responses
Code	Description	Links
200	
All cleared
No links

PATCH
/api/notifications/read
Mark notifications as read


Pass { "ids": [1, 2, 3] } to mark specific ones, or an empty body to mark all as read for the current user.

Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "ids": [
    1,
    2,
    3
  ]
}
Responses
Code	Description	Links
200	
Marked as read
No links
My Data
Personalised data for the logged-in user



GET
/api/my-data
Get personalised data for the currently logged-in user


Returns data scoped to the calling user's role. No query parameters needed — everything is resolved automatically from the JWT token.

admin / manager

Field	Description
profile	Own user record
stats.jobs	total, raised, assigned, in_progress, closed, open, total_revenue
stats.reports	total, pending, approved, rejected
stats.amc	total, active, expiring_soon, expired
stats.technicians	total, active, on_leave, inactive
stats.clients	total, active
recent.jobs	Last 20 jobs (all technicians)
recent.reports	Last 20 reports (all technicians)
recent.amc	Last 20 AMC contracts
recent.activity	Last 10 activity log entries
technician / engineer / labour

Field	Description
profile	Own user record
technician_profile	Linked technician record (null if not yet linked)
stats.jobs	Their assigned jobs only
stats.reports	Their submitted reports only
recent.jobs	Up to 50 jobs assigned to them
recent.reports	Up to 50 reports submitted by them
If the user has no linked technician profile, technician_profile will be null and a message field will explain why.

Parameters
Try it out
No parameters
Responses
Code	Description	Links
200	
Personalised data for the logged-in user
Media type

Controls Accept header.
Examples

Example Value
Schema
{
  "success": true,
  "role": "admin",
  "profile": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@vdti.com",
    "phone_number": "+919876543210",
    "role": "admin",
    "is_active": true,
    "last_login_at": "2026-05-06T08:30:00Z",
    "created_at": "2024-01-15T10:00:00Z"
  },
  "stats": {
    "jobs": {
      "total": 42,
      "raised": 5,
      "assigned": 10,
      "in_progress": 8,
      "closed": 19,
      "open": 23,
      "total_revenue": 875000
    },
    "reports": {
      "total": 31,
      "pending": 4,
      "approved": 25,
      "rejected": 2
    },
    "amc": {
      "total": 12,
      "active": 9,
      "expiring_soon": 2,
      "expired": 1
    },
    "technicians": {
      "total": 8,
      "active": 6,
      "on_leave": 1,
      "inactive": 1
    },
    "clients": {
      "total": 15,
      "active": 13
    }
  },
  "recent": {
    "jobs": [],
    "reports": [],
    "amc": [],
    "activity": []
  }
}
No links
401	
Unauthorized — missing or invalid token
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "TOKEN_MISSING",
  "message": "Access denied. No token provided. Please log in."
}
No links
Jobs
Visit Scheduled / Work order management



GET
/api/jobs
List all jobs with optional filters


Parameters
Try it out
Name	Description
page
integer
(query)
Default value : 1

limit
integer
(query)
Default value : 50

status
string
(query)
Available values : Raised, Assigned, In Progress, Closed

priority
string
(query)
Available values : Low, Medium, High, Critical

category
string
(query)
Available values : Maintenance, Repair, Installation, Inspection

client_id
integer
(query)

technician_id
integer
(query)

amc_id
string
(query)
Filter jobs linked to a specific AMC contract (e.g. AMC-0001)

search
string
(query)
Search by job ID or title

from_date
string($date)
(query)

to_date
string($date)
(query)

Responses
Code	Description	Links
200	
List of jobs
No links

POST
/api/jobs
Raise a new visit / work order


Creates a new job. If technician_id is provided, status auto-sets to Assigned. amc_id is optional — links the job to an AMC contract.

Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "title": "Quarterly Vacuum Pump Inspection",
  "description": "string",
  "client_id": 3,
  "technician_id": 2,
  "amc_id": "AMC-0001",
  "priority": "Medium",
  "category": "Maintenance",
  "scheduled_date": "2026-05-27",
  "amount": 0
}
Responses
Code	Description	Links
201	
Job raised
No links
400	
Validation error
No links

GET
/api/jobs/by-user/{user_id}
Get all jobs assigned to the technician linked to a user_id


Resolves the technician profile via user_id, then returns all jobs assigned to that technician. Supports optional status filter and pagination.

Parameters
Try it out
Name	Description
user_id *
integer
(path)
The user account ID (not the technician record ID)
Example : 5


status
string
(query)
Optional status filter
Available values : Raised, Assigned, In Progress, Closed


page
integer
(query)
Default value : 1

limit
integer
(query)
Default value : 50

Responses
Code	Description	Links
200	
Jobs for the technician linked to this user
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "technician": {
    "id": 0,
    "name": "string",
    "user_id": 0
  },
  "data": [
    {}
  ],
  "pagination": {}
}
No links
404	
No technician profile found for this user_id
No links

GET
/api/jobs/{id}
Get a single job with images, reports, and AMC info


Parameters
Try it out
Name	Description
id *
string
(path)
Example : JOB-0001

Responses
Code	Description	Links
200	
Job found (includes amc_id, amc_title, amc_status, amc_po_number)
No links
404	
Job not found
No links

PUT
/api/jobs/{id}
Update job details (not status — use PATCH for status)


Parameters
Try it out
Name	Description
id *
string
(path)
Example : JOB-0001

Request body

Example Value
Schema
{
  "title": "string",
  "description": "string",
  "technician_id": 0,
  "amc_id": "string",
  "priority": "string",
  "category": "string",
  "scheduled_date": "2026-05-27",
  "amount": 0
}
Responses
Code	Description	Links
200	
Job updated
No links
404	
Job not found
No links

DELETE
/api/jobs/{id}
Delete a job (admin only)


Parameters
Try it out
Name	Description
id *
string
(path)
Example : JOB-0001

Responses
Code	Description	Links
200	
Job deleted
No links
409	
Job has attached reports
No links

PATCH
/api/jobs/{id}/status
Advance job status through the pipeline


Parameters
Try it out
Name	Description
id *
string
(path)
Example : JOB-0001

Request body

Example Value
Schema
{
  "status": "Raised"
}
Responses
Code	Description	Links
200	
Status updated
No links
400	
Invalid transition
No links
404	
Job not found
No links

POST
/api/jobs/{id}/images
Add image(s) to a job


Parameters
Try it out
Name	Description
id *
string
(path)

Request body

Example Value
Schema
{
  "file_name": "string",
  "file_url": "string",
  "mime_type": "string",
  "file_size_bytes": 0
}
Responses
Code	Description	Links
201	
Image(s) added
No links

DELETE
/api/jobs/{id}/images/{imageId}
Delete a specific image from a job


Parameters
Try it out
Name	Description
id *
string
(path)

imageId *
integer
(path)

Responses
Code	Description	Links
200	
Image deleted
No links
ERP – Quotations
Read-only proxy to the external ERP Quotation API (http://203.192.195.67/erp/QuotationAPI.ashx). All responses are forwarded as-is from the ERP with a normalised wrapper.



GET
/api/erp/quotations
Get all quotations from ERP


Fetches quotation records from the external ERP system (QuotationAPI.ashx). Supports optional filtering and pagination via query parameters which are forwarded directly to the ERP.

Parameters
Try it out
Name	Description
page
integer
(query)
Page number for pagination
Default value : 1


limit
integer
(query)
Number of records per page
Default value : 50


customer_id
string
(query)
Filter quotations by ERP customer ID
Example : CUST-001


from_date
string($date)
(query)
Filter quotations from this date (YYYY-MM-DD)
Example : 2024-01-01


to_date
string($date)
(query)
Filter quotations up to this date (YYYY-MM-DD)
Example : 2024-12-31


status
string
(query)
Filter by quotation status
Available values : Draft, Confirmed, Cancelled


search
string
(query)
Free-text search (customer name, quotation number, etc.)

Responses
Code	Description	Links
200	
List of quotations fetched successfully from ERP
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "source": "erp",
  "count": 2,
  "data": [
    {
      "id": "QT-2024-00123",
      "customer_id": "CUST-001",
      "customer_name": "Acme Corp",
      "date": "2024-05-01",
      "status": "Confirmed",
      "total_amount": 45000
    },
    {
      "id": "QT-2024-00124",
      "customer_id": "CUST-002",
      "customer_name": "Beta Ltd",
      "date": "2024-05-03",
      "status": "Draft",
      "total_amount": 12500
    }
  ]
}
No links
401	
Unauthorised – JWT token missing or invalid
No links
500	
Internal server error
No links
502	
ERP returned an HTTP error
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "ERP_TIMEOUT",
  "message": "The ERP server did not respond in time. Please try again."
}
No links
504	
ERP did not respond within 15 seconds
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "ERP_TIMEOUT",
  "message": "The ERP server did not respond in time. Please try again."
}
No links

GET
/api/erp/quotations/{id}
Get a single quotation by ID from ERP


Fetches a specific quotation record from the external ERP system by passing id as a query parameter to QuotationAPI.ashx.

Parameters
Try it out
Name	Description
id *
string
(path)
ERP quotation ID (e.g. QT-2024-00123)
Example : QT-2024-00123


Responses
Code	Description	Links
200	
Quotation record fetched successfully
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "source": "erp",
  "data": {
    "id": "QT-2024-00123",
    "customer_id": "CUST-001",
    "customer_name": "Acme Corp",
    "date": "2024-05-01",
    "valid_until": "2024-06-01",
    "status": "Confirmed",
    "total_amount": 45000,
    "currency": "INR",
    "items": [
      {
        "description": "Annual Maintenance Contract",
        "quantity": 1,
        "unit_price": 45000,
        "total": 45000
      }
    ]
  }
}
No links
401	
Unauthorised – JWT token missing or invalid
No links
404	
Quotation not found in ERP
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "QUOTATION_NOT_FOUND",
  "message": "Quotation with ID 'QT-2024-00123' was not found in the ERP."
}
No links
500	
Internal server error
No links
502	
ERP returned an HTTP error
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "ERP_TIMEOUT",
  "message": "The ERP server did not respond in time. Please try again."
}
No links
504	
ERP did not respond within 15 seconds
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "ERP_TIMEOUT",
  "message": "The ERP server did not respond in time. Please try again."
}
No links
ERP – Customers
Read-only proxy to the external ERP Customer API (http://203.192.195.67/erp/CustomerAPI.ashx). All responses are forwarded as-is from the ERP with a normalised wrapper.



GET
/api/erp/customers
Get all customers from ERP


Fetches customer records from the external ERP system (CustomerAPI.ashx). Supports optional filtering and pagination via query parameters which are forwarded directly to the ERP.

Parameters
Try it out
Name	Description
page
integer
(query)
Page number for pagination
Default value : 1


limit
integer
(query)
Number of records per page
Default value : 50


search
string
(query)
Search by customer name, phone, or email
Example : Acme


status
string
(query)
Filter by customer status
Available values : Active, Inactive


Responses
Code	Description	Links
200	
List of customers fetched successfully from ERP
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "source": "erp",
  "count": 2,
  "data": [
    {
      "id": "CUST-001",
      "name": "Acme Corp",
      "email": "contact@acme.com",
      "phone": "+911234567890",
      "status": "Active"
    },
    {
      "id": "CUST-002",
      "name": "Beta Ltd",
      "email": "info@beta.com",
      "phone": "+919876543210",
      "status": "Active"
    }
  ]
}
No links
401	
Unauthorised – JWT token missing or invalid
No links
500	
Internal server error
No links
502	
ERP returned an HTTP error
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "ERP_TIMEOUT",
  "message": "The ERP server did not respond in time. Please try again."
}
No links
504	
ERP did not respond within 15 seconds
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "ERP_TIMEOUT",
  "message": "The ERP server did not respond in time. Please try again."
}
No links

GET
/api/erp/customers/{id}
Get a single customer by ID from ERP


Fetches a specific customer record from the external ERP system by passing id as a query parameter to CustomerAPI.ashx.

Parameters
Try it out
Name	Description
id *
string
(path)
ERP customer ID (e.g. CUST-001)
Example : CUST-001


Responses
Code	Description	Links
200	
Customer record fetched successfully
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "source": "erp",
  "data": {
    "id": "CUST-001",
    "name": "Acme Corp",
    "email": "contact@acme.com",
    "phone": "+911234567890",
    "address": "123 Industrial Area, Mumbai",
    "gstin": "27AABCU9603R1ZX",
    "status": "Active",
    "created_date": "2023-01-15"
  }
}
No links
401	
Unauthorised – JWT token missing or invalid
No links
404	
Customer not found in ERP
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "CUSTOMER_NOT_FOUND",
  "message": "Customer with ID 'CUST-001' was not found in the ERP."
}
No links
500	
Internal server error
No links
502	
ERP returned an HTTP error
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "ERP_TIMEOUT",
  "message": "The ERP server did not respond in time. Please try again."
}
No links
504	
ERP did not respond within 15 seconds
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "ERP_TIMEOUT",
  "message": "The ERP server did not respond in time. Please try again."
}
No links
Email Settings
SMTP configuration and notification trigger management (admin only)



GET
/api/email-settings
Get current SMTP settings and notification triggers


SMTP password is never returned in the response.

Parameters
Try it out
No parameters
Responses
Code	Description	Links
200	
Email settings found (or null if not configured yet)
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "data": {
    "id": 0,
    "smtp_host": "smtp.gmail.com",
    "smtp_port": 587,
    "from_email": "notifications@vdti.com",
    "from_name": "VDTI Service Hub",
    "is_active": true,
    "updated_at": "2026-05-27T10:33:25.942Z",
    "notifications": {
      "job_raised": true,
      "job_assigned": true,
      "job_completed": true,
      "report_approved": false,
      "amc_renewal": true,
      "quotation_sent": false
    }
  }
}
No links

PUT
/api/email-settings
Create or update SMTP settings and notification triggers


This is an upsert — creates settings on first call, updates on subsequent calls.

If smtp_password is omitted on update, the existing password is kept.
notifications is a map of trigger keys to booleans.
Available trigger keys: job_raised, job_assigned, job_completed, report_approved, amc_renewal, quotation_sent
Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "smtp_host": "smtp.gmail.com",
  "smtp_port": 587,
  "from_email": "notifications@vdti.com",
  "from_name": "VDTI Service Hub",
  "smtp_password": "app-specific-password-here",
  "notifications": {
    "job_raised": true,
    "job_assigned": true,
    "job_completed": true,
    "report_approved": false,
    "amc_renewal": true,
    "quotation_sent": false
  }
}
Responses
Code	Description	Links
200	
Settings saved
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string",
  "data": {
    "id": 0,
    "smtp_host": "smtp.gmail.com",
    "smtp_port": 587,
    "from_email": "notifications@vdti.com",
    "from_name": "VDTI Service Hub",
    "is_active": true,
    "updated_at": "2026-05-27T10:33:25.950Z",
    "notifications": {
      "job_raised": true,
      "job_assigned": true,
      "job_completed": true,
      "report_approved": false,
      "amc_renewal": true,
      "quotation_sent": false
    }
  }
}
No links
400	
Validation error
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

POST
/api/email-settings/test
Send a test email using current SMTP settings


Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "to": "admin@vdti.com"
}
Responses
Code	Description	Links
200	
Test email sent
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string"
}
No links
400	
No settings configured or missing password
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
500	
SMTP connection failed
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
Data
Specialized data listing and dashboard APIs



GET
/api/data/visit-schedule
List simplified visit schedule (jobs)


Parameters
Try it out
No parameters
Responses
Code	Description	Links
200	
Success
No links

GET
/api/data/reports
List simplified service reports


Parameters
Try it out
No parameters
Responses
Code	Description	Links
200	
Success
No links

GET
/api/data/dashboard-user-wise
Get user-wise dashboard stats for Jobs and Reports


Parameters
Try it out
No parameters
Responses
Code	Description	Links
200	
Success
No links
Dashboard
Dashboard KPIs, charts and recent activity



GET
/api/dashboard
Get all dashboard data in one request


Returns everything needed to render the full dashboard UI:

stats — KPI cards (Active Jobs, Total Clients, Technicians, Revenue)
job_status_breakdown — data for the donut chart (Raised / Assigned / In Progress / Closed)
monthly_stats — last 6 months bar chart (jobs raised, jobs completed, revenue)
revenue_trend — last 6 months line chart (revenue only)
quick_overview — progress bar section (Jobs This Month, Jobs Completed, Active Technicians, AMC Active)
recent_jobs — last 10 work orders for the Recent Work Orders table
Parameters
Try it out
No parameters
Responses
Code	Description	Links
200	
Dashboard data
Media type

Controls Accept header.
Example Value
Schema
"string"
No links
401	
Unauthorized
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
Clients
Client organisation management



GET
/api/clients
List all clients with optional filters


Parameters
Try it out
Name	Description
page
integer
(query)
Default value : 1

limit
integer
(query)
Default value : 50

type
string
(query)
Available values : Corporate, Residential, Commercial, Healthcare, Government

status
string
(query)
Available values : Active, Inactive

search
string
(query)
Search by name or contact person

Responses
Code	Description	Links
200	
List of clients
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "data": [
    {
      "id": 0,
      "name": "string",
      "contact_person": "string",
      "email": "string",
      "phone": "string",
      "gst_no": "string",
      "address": "string",
      "type": "Corporate",
      "status": "Active",
      "contract_value": 0,
      "join_date": "2026-05-27",
      "created_at": "2026-05-27T10:33:25.970Z",
      "updated_at": "2026-05-27T10:33:25.970Z"
    }
  ],
  "pagination": {
    "total": 0,
    "page": 0,
    "limit": 0,
    "total_pages": 0
  }
}
No links
401	
Unauthorized
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

POST
/api/clients
Add a new client


Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "name": "Rainbow Tech Park",
  "contact_person": "Sunita Menon",
  "email": "user@example.com",
  "phone": "string",
  "gst_no": "27AAACG1234A1Z5",
  "address": "string",
  "type": "Corporate",
  "status": "Active",
  "contract_value": 250000
}
Responses
Code	Description	Links
201	
Client created successfully
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string",
  "data": {
    "id": 0,
    "name": "string",
    "contact_person": "string",
    "email": "string",
    "phone": "string",
    "gst_no": "string",
    "address": "string",
    "type": "Corporate",
    "status": "Active",
    "contract_value": 0,
    "join_date": "2026-05-27",
    "created_at": "2026-05-27T10:33:25.977Z",
    "updated_at": "2026-05-27T10:33:25.977Z"
  }
}
No links
400	
Validation error
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

GET
/api/clients/{id}
Get a single client with job and AMC stats


Parameters
Try it out
Name	Description
id *
integer
(path)

Responses
Code	Description	Links
200	
Client found
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "data": "string"
}
No links
404	
Client not found
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

PUT
/api/clients/{id}
Update a client record


Parameters
Try it out
Name	Description
id *
integer
(path)

Request body

Example Value
Schema
{
  "name": "string",
  "contact_person": "string",
  "email": "user@example.com",
  "phone": "string",
  "gst_no": "string",
  "address": "string",
  "type": "Corporate",
  "status": "Active",
  "contract_value": 0
}
Responses
Code	Description	Links
200	
Client updated
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string",
  "data": {
    "id": 0,
    "name": "string",
    "contact_person": "string",
    "email": "string",
    "phone": "string",
    "gst_no": "string",
    "address": "string",
    "type": "Corporate",
    "status": "Active",
    "contract_value": 0,
    "join_date": "2026-05-27",
    "created_at": "2026-05-27T10:33:25.986Z",
    "updated_at": "2026-05-27T10:33:25.986Z"
  }
}
No links
400	
Validation error
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
404	
Client not found
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

DELETE
/api/clients/{id}
Delete a client (admin or manager only)


Cannot delete if client has open jobs or active AMC contracts.

Parameters
Try it out
Name	Description
id *
integer
(path)

Responses
Code	Description	Links
200	
Client deleted
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string"
}
No links
404	
Client not found
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
409	
Client has open jobs or active AMC
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
Auth
Authentication APIs



POST
/api/auth/register
Register a new user

Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john@example.com",
  "phone_number": "+911234567890",
  "password": "password123",
  "role": "admin"
}
Responses
Code	Description	Links
201	
User registered successfully
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string",
  "token": "string",
  "user": {
    "id": 0,
    "first_name": "string",
    "last_name": "string",
    "email": "string",
    "phone_number": "string",
    "role": "admin",
    "is_active": true,
    "last_login_at": "2026-05-27T10:33:25.997Z",
    "created_at": "2026-05-27T10:33:25.997Z",
    "updated_at": "2026-05-27T10:33:25.997Z"
  }
}
No links
400	
Validation error
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links
409	
Email or phone already registered
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

POST
/api/auth/login
Login with email or phone number + password

Parameters
Try it out
No parameters
Request body

Examples: 
Example Value
Schema
{
  "email": "john@example.com",
  "password": "password123"
}
Responses
Code	Description	Links
200	
Login successful
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string",
  "token": "string",
  "user": {
    "id": 0,
    "first_name": "string",
    "last_name": "string",
    "email": "string",
    "phone_number": "string",
    "role": "admin",
    "is_active": true,
    "last_login_at": "2026-05-27T10:33:26.010Z",
    "created_at": "2026-05-27T10:33:26.010Z",
    "updated_at": "2026-05-27T10:33:26.010Z"
  }
}
No links
401	
Invalid credentials
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

GET
/api/auth/me
Get authenticated user details


Parameters
Try it out
No parameters
Responses
Code	Description	Links
200	
Authenticated user details
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "user": {
    "id": 0,
    "first_name": "string",
    "last_name": "string",
    "email": "string",
    "phone_number": "string",
    "role": "admin",
    "is_active": true,
    "last_login_at": "2026-05-27T10:33:26.013Z",
    "created_at": "2026-05-27T10:33:26.013Z",
    "updated_at": "2026-05-27T10:33:26.013Z"
  }
}
No links
401	
Unauthorized
Media type

Example Value
Schema
{
  "success": false,
  "error_code": "JOB_NOT_FOUND",
  "message": "string",
  "details": {}
}
No links

POST
/api/auth/forgot-password
Request a password reset token

Sends a reset token to the registered email. Token expires in 15 minutes. Always returns success to prevent email enumeration. In production, remove dev_only_reset_token and send via email instead.

Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "email": "john@example.com"
}
Responses
Code	Description	Links
200	
Token generated (or silently ignored if email not found)
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "message": "string",
  "dev_only_reset_token": "string",
  "expires_at": "2026-05-27T10:33:26.020Z"
}
No links
400	
Email is required
No links

POST
/api/auth/reset-password
Reset password using the token from forgot-password

Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "token": "a3f5c9e2b1d4...",
  "new_password": "newSecurePass123",
  "confirm_password": "newSecurePass123"
}
Responses
Code	Description	Links
200	
Password reset successfully
No links
400	
Invalid/expired token or password mismatch
No links

POST
/api/auth/change-password
Change password (authenticated user)


Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "current_password": "oldPassword123",
  "new_password": "newPassword456",
  "confirm_password": "newPassword456"
}
Responses
Code	Description	Links
200	
Password changed successfully
No links
400	
Validation error
No links
401	
Current password is incorrect
No links
AMC Contracts
Annual Maintenance Contract management



GET
/api/amc/expiring
Get AMC contracts whose renewal reminder fires today


Parameters
Try it out
No parameters
Responses
Code	Description	Links
200	
List of expiring contracts
No links

GET
/api/amc
List all AMC contracts with optional filters


Parameters
Try it out
Name	Description
page
integer
(query)
Default value : 1

limit
integer
(query)
Default value : 50

status
string
(query)
Available values : Active, Expiring Soon, Expired

client_id
integer
(query)

po_number
string
(query)
Filter by PO Number

Responses
Code	Description	Links
200	
List of AMC contracts
No links

POST
/api/amc
Create a new AMC contract


Creates the contract and sends a confirmation email to the client. The cron job will send a renewal reminder email when expiry is within renewal_reminder_days, and a 10-day service reminder based on next_service_date.

Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "client_id": 5,
  "title": "Annual Vacuum System Maintenance 2025",
  "po_number": "PO-2025-001",
  "start_date": "2025-01-01",
  "end_date": "2025-12-31",
  "value": 75000,
  "next_service_date": "2025-04-15",
  "renewal_reminder_days": 30,
  "services": [
    "Preventive Maintenance",
    "Emergency Repairs",
    "Spare Parts"
  ]
}
Responses
Code	Description	Links
201	
AMC contract created and confirmation email sent
No links
400	
Validation error
No links

GET
/api/amc/{id}
Get a single AMC contract with services list


Parameters
Try it out
Name	Description
id *
string
(path)
Example : AMC-0001

Responses
Code	Description	Links
200	
AMC contract found
No links
404	
Not found
No links

PUT
/api/amc/{id}
Update an AMC contract


If services array is provided, it fully replaces the existing services list.

Parameters
Try it out
Name	Description
id *
string
(path)
Example : AMC-0001

Request body

Example Value
Schema
{
  "title": "string",
  "po_number": "string",
  "end_date": "2026-05-27",
  "value": 0,
  "next_service_date": "2026-05-27",
  "renewal_reminder_days": 0,
  "services": [
    "string"
  ]
}
Responses
Code	Description	Links
200	
AMC updated
No links
404	
Not found
No links

DELETE
/api/amc/{id}
Delete an AMC contract (admin only)


Parameters
Try it out
Name	Description
id *
string
(path)
Example : AMC-0001

Responses
Code	Description	Links
200	
Deleted
No links
404	
Not found
No links
Activity
System-wide audit/activity log



GET
/api/activity
Get paginated activity log (optionally filtered by module type)


Parameters
Try it out
Name	Description
type
string
(query)
Filter by module type
Available values : job, report, client, technician, amc, user, auth, email_settings


page
integer
(query)
Default value : 1

limit
integer
(query)
Default value : 30

Responses
Code	Description	Links
200	
Paginated activity log
Media type

Controls Accept header.
Example Value
Schema
{
  "success": true,
  "data": [
    {
      "id": 0,
      "type": "job",
      "action": "Job JOB-0001 raised — HVAC Servicing",
      "entity_type": "string",
      "entity_id": "JOB-0001",
      "performed_at": "2026-05-27T10:33:26.056Z",
      "performed_by": {
        "id": 0,
        "name": "string",
        "role": "string"
      }
    }
  ],
  "pagination": {
    "total": 0,
    "page": 0,
    "limit": 0,
    "total_pages": 0
  }
}
No links

Schemas
RegisterRequest
LoginRequest
UserResponse
CreateUserRequest
UpdateUserRequest
AuthResponse
PaginatedUsersResponse
TechnicianResponse
CreateTechnicianRequest
UpdateTechnicianRequest
PaginatedTechniciansResponse
ClientResponse
CreateClientRequest
UpdateClientRequest
PaginatedClientsResponse
JobResponse
CreateJobRequest
UpdateJobRequest
UpdateJobStatusRequest
PaginatedJobsResponse
ReportResponse
CreateReportRequest
UpdateReportStatusRequest
PaginatedReportsResponse
AmcResponse
AmcExpiringResponse
CreateAmcRequest
UpdateAmcRequest
PaginatedAmcResponse
EmailSettingsResponse
UpsertEmailSettingsRequest
UploadResponse
AddImageRequest
ImageUploadItem
ImageResponse
Pagination
ErrorResponse
SuccessMessageResponse
MyDataResponse
ErpQuotation
ErpQuotationListResponse
ErpQuotationSingleResponse
ErpCustomer
ErpCustomerListResponse
ErpCustomerSingleResponse
ErpErrorResponse