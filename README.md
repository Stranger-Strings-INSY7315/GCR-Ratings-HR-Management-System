# HR Management System for GCR Ratings

## Overview

This repository contains a Salesforce-native HR Management System built for **GCR Ratings – An Affiliate of Moody's**. The system streamlines HR processes through two dedicated portals: an Employee app for self-service tasks, and an HR/Admin portal for managing the full employee lifecycle.

The system is built entirely on the Salesforce Platform, using declarative tools (custom objects, permission sets, flows) and custom development (Apex, Lightning Web Components) rather than a traditional separate front-end/back-end/database stack.

## Team

**Group Name:** Stranger Strings

| Name | Student Number |
|---|---|
| Humza Ali | ST10445149 |
| Muhammad Seedat | ST10441173 |

**Module:** INSY7315 — Work Integrated Learning

## Client

GCR Ratings – An Affiliate of Moody's

## Task 2 Implementation Presentation

A recorded walkthrough of the system (architecture, database and APIs, security, GitHub workflow, live demo of both portals, and deployment) is available here:

**[Watch the presentation (16:45)](https://youtu.be/iGqEr27ww1s)**

## Features

### Employee App
- View and manage personal profile
- Submit and track leave requests, view leave balances
- View assigned training courses and mark training as complete
- View and download HR documents (contracts, payslips, policies)
- View finalized performance reviews
- View personal attendance records

### HR/Admin Portal
- Manage employee records and departments
- Approve or reject leave requests
- Assign and track training courses across employees
- Create, manage and finalize performance reviews
- Upload and manage HR documents per employee
- View real-time HR Dashboard — employee counts, leave status breakdown, training completion rates, review statistics, and monthly attendance, all built with native Apex aggregate queries and CSS-based data visualization

## Technology Stack

- **Platform:** Salesforce (Developer Edition)
- **Backend:** Apex (classes, triggers, test classes)
- **Frontend:** Lightning Web Components (LWC), HTML, CSS, JavaScript
- **Automation:** Salesforce Flow Builder
- **Database:** Native Salesforce custom objects (declarative schema, no external database)
- **APIs:** Salesforce REST/SOAP APIs (auto-exposed per object/class), Lightning Data Service
- **Security:** Multi-Factor Authentication, field-level security via Permission Sets, session security policies, `WITH USER_MODE` enforced SOQL, CRUD/FLS-safe Apex
- **CI/CD:** GitHub Actions

## Architecture & Hosting

This system does not use a separately hosted front end, back end, and database. Salesforce is used as an integrated Platform-as-a-Service (PaaS), where a single platform provides all four layers:

- **Hosting:** Both the Employee app and HR Admin Portal run live on our Salesforce Developer Edition org, accessible at `https://orgfarm-4e4e346ad9-dev-ed.develop.my.salesforce.com`, reachable immediately by any authenticated user with no separate deployment step.
- **Front end:** Lightning Web Components, rendered natively by the platform, with layouts that adapt automatically to desktop and mobile screen sizes via the Lightning Design System. The Employee app is also accessible on mobile through the official Salesforce mobile app (iOS/Android), with no separate native app build required.
- **Back end:** Apex classes (e.g. `HRDashboardController`, `DocumentAdminController`) exposed to the front end via `@AuraEnabled` methods.
- **Database:** Native Salesforce custom objects (`Employee__c`, `Leave__c`, `Document__c`, `Performance_Review__c`, `Employee_Training__c`, `Attendance__c`, etc.) with enforced relationships, validation rules, and sharing settings.
- **APIs:** Salesforce automatically exposes REST and SOAP APIs for every custom object and Apex class the moment it is deployed — live and callable without additional configuration.

Because all four layers run on one platform, there is no inter-service connectivity to separately configure or that can fail — front end, back end, database and APIs communicate in-process.

**Why Salesforce was chosen over a traditional separately-hosted stack:**
- Enterprise-grade uptime — Salesforce's production infrastructure is backed by a 99.9%+ uptime SLA, exceeding what a self-hosted or free-tier deployment could offer for a project of this scope.
- No infrastructure management overhead — Salesforce handles scaling, patching, backups and server maintenance automatically.
- Built-in security and compliance — platform-level encryption, audit trails, and enforced sharing models come standard, which matters for an HR system handling sensitive data for a financial-services-adjacent client.
- Consistency with the client's own environment — GCR Ratings runs on enterprise software, so delivering their HR tool on an equally enterprise-grade platform matches their reliability expectations.
- Native integration — avoids building custom API connectors to replicate what Salesforce already provides.

This decision was made deliberately at project start (see Task 1 documentation) and remains the correct choice for a system of this type and scale.

## Security

Full details are documented in [`docs/Security_Implementation_Documentation.docx`](docs/Security_Implementation_Documentation.docx), covering:
- Multi-Factor Authentication (MFA) and password policy hardening
- Session timeout and HttpOnly cookie protection
- CSRF and clickjack protection
- Field-level security audit across all permission sets
- `WITH USER_MODE` enforcement in all SOQL queries to prevent SOQL injection and privilege escalation
- Documented security trade-offs (e.g. Login IP Restrictions intentionally not enforced, with rationale)

## CI/CD Pipeline

A GitHub Actions workflow (`.github/workflows/ci.yml`) runs automatically on every push and pull request to `develop` and `main`. It:
1. Checks out the source code
2. Installs the Salesforce CLI
3. Authenticates to the Salesforce org using an encrypted GitHub Secret (no credentials are stored in the repository)
4. Deploys the metadata and runs all local Apex tests (`RunLocalTests`)

A failing test fails the pipeline, giving immediate feedback before changes are merged. Run history is visible under the repository's **Actions** tab.

## Project Structure

HR-Management-System/
│
├── .github/
│ └── workflows/
│ └── ci.yml # CI/CD pipeline (GitHub Actions)
│
├── force-app/
│ └── main/default/
│ ├── classes/ # Apex classes & test classes
│ ├── lwc/ # Lightning Web Components
│ ├── flexipages/ # Lightning App Page layouts
│ ├── tabs/ # Custom tab definitions
│ ├── objects/ # Custom object & field metadata
│ ├── permissionsets/ # HR_Admin_Access, HR_Employee_Access
│ └── settings/ # Org security settings (MFA, session, password policy)
│
├── docs/ # Project documentation (incl. Security docs)
├── assets/ # Images and resources
└── README.md


## Setup / Deployment

1. Install [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli).
2. Clone this repository:

git clone <repo-url>
cd HR-Management-System

3. Authenticate to a Salesforce org:

sf org login web --alias GCR-Dev

4. Deploy the metadata:

sf project deploy start --target-org GCR-Dev

5. Assign the relevant permission set to your user (`HR_Admin_Access` or `HR_Employee_Access`) via Setup → Users → Permission Set Assignments.
6. Open the relevant Lightning App (`GCR HR Admin Portal` or the Employee app) via the App Launcher.

## Branch Strategy

- `main` – Stable, production-ready code
- `develop` – Active development, integration branch
- `feature/*` – Individual features, branched from `develop`
- `bugfix/*` – Bug fixes

## Version Control Workflow

- Pull the latest changes from `develop` before starting new work
- Create a feature branch for each piece of work
- Commit regularly with meaningful, conventional commit messages (e.g. `feat: Add leave approval flow`, `fix: Correct FLS on Audit Logs object`)
- Open a pull request into `develop` for review before merging
- Sync local `develop` after every merge

## Team Values

Collaboration · Innovation · Accountability · Continuous Learning · Quality

## Current Status

**Task 2 (Code and Implementation) is complete.** All core HR functionality (Employee self-service, HR/Admin management, document handling, reporting & dashboards) and full security hardening have been implemented, tested, and deployed. The system is live and fully functional on our Salesforce Developer Edition org.

## License

This project is developed for educational purposes as part of a university software development module.

© 2026 Stranger Strings
