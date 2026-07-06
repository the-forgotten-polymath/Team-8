# Cross-Module Data Integration Architecture

This document serves as the master reference guide for ensuring seamless and error-free data synchronization between the **Employee App**, **Store Admin Module**, and any future modules (e.g., Inventory, Corporate Dashboard) connected to the Supabase backend.

## 1. Core Principles

- **Single Source of Truth**: All modules must read from and write directly to the centralized Supabase database. Do not cache mutable global states locally without syncing.
- **Foreign Key Integrity**: Modules must reference canonical IDs (e.g., `employee_id`, `store_id`).
- **Enum Strictness**: Always use exact string raw values mapped to PostgreSQL Enums.

---

## 2. Global Enums (Strict Mapping Required)

When building new modules, your data models MUST map precisely to these PostgreSQL enums to prevent `invalid input value for enum` crashes.

| Enum Name | Allowed Values |
| --- | --- |
| `staff_role` | `'Sales Associate'`, `'Inventory Controller'`, `'Boutique Manager'`, `'Area Manager'`, `'Corporate Admin'`, `'Super Admin'` |
| `employment_status` | `'active'`, `'onLeave'`, `'probation'`, `'suspended'`, `'terminated'` |
| `attendance_status` | `'present'`, `'late'`, `'absent'`, `'onLeave'` |
| `leave_type` | `'annual'`, `'sick'`, `'personal'`, `'emergency'` |
| `approval_status` | `'pending'`, `'approved'`, `'rejected'` |
| `goal_status` | `'Not Started'`, `'In Progress'`, `'Achieved'`, `'Missed'` |

> [!CAUTION]
> Inserting a record with a value like `"Pending"` (capitalized) into an `approval_status` column will crash the database transaction. Always use lowercase or exact casing matching the enum.

---

## 3. Key Data Flows & Cross-Module Interactions

### A. Attendance & Clock-In/Out
*Table: `attendance_records`*
- **Employee App Action**: Employee clicks "Clock In". App inserts a record with `employee_id`, `shift_id`, `clock_in_time`, and GPS coordinates.
- **Store Admin Module Visibility**: The Store Admin dashboard should listen to changes in `attendance_records` (via Supabase Realtime). The Admin UI will immediately reflect the clock-in status, allowing managers to see who is on the floor.
- **Critical Fields**: `status` must update from `'absent'` to `'present'` or `'late'`.

### B. Shift Scheduling
*Table: `shifts`*
- **Store Admin Module Action**: Store Manager creates a shift, assigning an `employee_id` and a `store_id`.
- **Employee App Visibility**: The employee sees the shift instantly. 
- **Integrity**: `store_id` ensures the shift belongs to the correct physical location. If a manager swaps a shift, the `status` field changes (e.g., `'swapped'`) and a new shift record is created.

### C. Leave Requests & Approvals
*Table: `leave_requests` & `leave_balances`*
- **Employee App Action**: Employee submits a leave request. A row is inserted in `leave_requests` with status `'pending'`.
- **Store Admin Module Action**: Manager reviews and updates status to `'approved'`.
- **Database Trigger (Recommended)**: Upon an `'approved'` status, a database function should automatically deduct the `days_requested` from the corresponding column (`annual_remaining`, etc.) in the `leave_balances` table.

### D. Expense Claims
*Table: `expense_claims`*
- **Employee App Action**: Employee uploads receipts (files go to `expense-receipts` bucket, returning a URL array) and inserts a claim.
- **Store Admin / Finance Module**: Finance reviews the claim, updating `status` from `'pending'` to `'approved'` and eventually `'paid'`. The `reviewed_by` field captures the admin's UUID for auditability.

### E. Goal Tracking & KPIs
*Table: `goals`, `kpis`, `commissions`*
- **POS / Inventory Module Integration**: When a sale is made (`sales_transactions`), the system must update the `current_value` in the `goals` table and `commission_earned` in the `commissions` table.
- **Employee App Visibility**: The Employee App reads these values to show progress bars in the Performance tab in real-time.

---

## 4. Row Level Security (RLS) Reminders

When building admin modules, remember that your database uses RLS:
- **Employee App Tokens**: Are scoped to `auth.uid() = employee_id`. Employees can only view their own shifts, attendance, and documents.
- **Admin App Tokens**: Store Managers / Admins must have logic that bypasses strict self-only constraints. 
  - *Recommendation*: You will need to add RLS policies allowing managers to select rows where their `id` matches the `reporting_manager_id` of the target employee, OR where they share a `primary_store_id` and the viewer has a `staff_role` of `'Boutique Manager'`.

---

## 5. Storage Buckets & File Sharing

| Bucket Name | Accessibility | Purpose |
| --- | --- | --- |
| `profile-photos` | Public | Employee avatars visible across all modules. |
| `training-content` | Public | Static MP4s, PDFs for learning modules. |
| `document-vault` | Private (RLS protected) | Payslips, contracts, sensitive HR info. |
| `expense-receipts` | Private (RLS protected) | Photos of receipts for reimbursements. |

> [!IMPORTANT]
> When rendering private files in the Employee App or Admin App, you must use Supabase's `createSignedUrl` API to generate a temporary, viewable link, rather than using the raw storage path.
