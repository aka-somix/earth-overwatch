# Earth Overwatch

[![Cloud](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazon-aws&style=for-the-badge)](https://aws.amazon.com)
[![IaC](https://img.shields.io/badge/IaC-Terraform-8A2BE2?logo=terraform&style=for-the-badge)](https://terraform.io)
[![Vue](https://img.shields.io/badge/Frontend-Vue_3-4FC08D?logo=vue.js&style=for-the-badge)](https://vuejs.org)
[![ML](https://img.shields.io/badge/ML-SageMaker-FF9900?logo=amazon-sagemaker&style=for-the-badge)](https://aws.amazon.com/sagemaker)

Earth Overwatch is an **end-to-end system for detecting and monitoring illegal landfills from satellite and aerial imagery** using computer vision. It combines a web-based interactive map, a cloud-native backend, and machine learning models (YOLO, DETR) deployed on AWS.

---

## For Non-Technical Stakeholders

### What does it do?

Illegal dumping is a widespread environmental problem. Municipalities waste millions patrolling vast territories looking for landfills. **Earth Overwatch automates this** by analyzing satellite/aerial images with AI to flag potential landfills — so inspectors know exactly where to go.

### How does it work?

1. **Aerial imagery** is collected from open data sources (OpenAerialMap)
2. **AI models** (YOLO and DETR) scan the images for patterns that look like landfills
3. **Detections** are stored in a geospatial database with confidence scores, dates, and locations
4. **A web map** lets users browse Italian regions, drill into municipalities, and inspect flagged zones — complete with satellite overlay and detection details

### Who is it for?

- **Environmental agencies** looking to monitor territory at scale
- **Municipalities** needing data-driven inspection targeting
- **Researchers** studying remote sensing for environmental monitoring

---

## System Architecture

```
                          ┌──────────────────────────────┐
                          │      Earth Overwatch         │
                          └──────────────────────────────┘

  ┌───────────┐      ┌──────────────────────┐      ┌──────────────┐
  │  Web App  │      │  API Layer           │      │  ML Pipeline │
  │  (Vue 3)  │◄────►│  (API Gateway +      │◄────►│  (SageMaker) │
  │  Leaflet  │      │   Express Lambdas)   │      │  YOLO/DETR   │
  │  Quasar   │      │  Geo · Detections    │      │              │
  └───────────┘      └──────────┬───────────┘      └──────────────┘
                                │                           │
                                ▼                           │
                       ┌────────────────┐                  │
                       │  Aurora        │                  │
                       │  Serverless    │◄─────────────────┘
                       │  PostGIS       │     Detection results
                       └────────────────┘

  ┌──────────────────────────────────────────────────────────────┐
  │                  Infrastructure (Terraform)                  │
  │  VPC · Bastion · EventBridge · SQS · S3 · IAM · Lambda     │
  └──────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Ingest** — Aerial imagery is pulled from OpenAerialMap via the data platform ingestion pipeline
2. **Detect** — New images trigger EventBridge → Step Functions → SageMaker inference (YOLO/DETR)
3. **Store** — Detection results (polygons, confidence scores) land in Aurora Serverless with PostGIS
4. **Serve** — Express Lambda APIs (Geo, Detections) behind API Gateway serve data to the frontend
5. **Explore** — Users browse the interactive map: select an Italian region → click a municipality → view landfill detections

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Vue 3, TypeScript, Quasar, Leaflet, Pinia, Vite, Sass |
| **APIs** | Node.js, Express, TypeScript, serverless-http, Zod |
| **Database** | Aurora Serverless PostgreSQL 16.3 + PostGIS |
| **ML Models** | YOLO11m (Ultralytics), DETR50 (HuggingFace) — SageMaker Serverless |
| **Infrastructure** | Terraform, Terragrunt, AWS (Lambda, API Gateway, SQS, EventBridge, S3, IAM, VPC) |
| **Package Manager** | pnpm (all Node.js packages) |
| **Pipeline Scripts** | Bash (deployment), Python (data upload, inference) |

---

## Repository Structure

```
earth-overwatch/
├── Makefile              # Top-level automation (make app/mlpipe/web <cmd>)
├── config.yaml           # Shared config: project name, regions, tags
│
├── web/                  # Vue 3 SPA — interactive map frontend
│   ├── src/
│   │   ├── components/   # Leaflet layers & dialogs (regions, municipalities, zones)
│   │   ├── views/        # Pages: SplashScreen, Map, Zones, About
│   │   ├── api/          # OpenAPI-generated clients for Geo & Landfills APIs
│   │   ├── router/       # Vue Router config
│   │   └── layouts/      # App layout with navigation drawer
│   └── vite.config.ts
│
├── app/                  # Main IaC — Terraform/Terragrunt stacks
│   ├── config/dev.yaml   # Dev environment config
│   └── stacks/
│       ├── network/      # VPC & security groups
│       ├── bastion/      # Bastion EC2 Auto Scaling Group (SSM tunnel for DB)
│       ├── events-broker/# EventBridge buses (dataplatform + backend)
│       ├── geo/          # Aurora PostGIS DB + Geo/Monitor API services
│       │   └── api-services/
│       │       ├── geo/  # Regions & municipalities REST API (Express + Drizzle)
│       │       └── monitor/ # Monitoring API
│       ├── components/
│       │   └── landfills/# Detections API, detection pipeline (Step Functions + SQS + Lambdas)
│       │       ├── api-services/detections/  # Landfill detections REST API (Express + pg)
│       │       ├── detection/                # Python Lambdas for model inference
│       │       └── new-data-handler/         # Lambda for incoming imagery events
│       └── dataplatform/ # Data ingestion (OAM) & image tiling processing
│
├── mlpipe/               # ML Pipeline IaC
│   ├── config/dev.yaml   # ML dev config
│   └── stacks/
│       ├── sagemaker/    # SageMaker execution role + notebook instance
│       ├── aimodels/
│       │   └── landfill/ # YOLO & DETR50 model definitions + inference code
│       ├── storage/      # EFS dataset filesystem
│       └── network/      # ML VPC resources
│
└── scripts/
    ├── cleanup.sh        # Stop EC2, delete API stages, teardown notebooks
    ├── dbconn.sh         # SSH tunnel via Bastion to Aurora
    ├── build-geo-db/     # Upload Italian regions & municipalities to PostGIS
    └── notebooks/        # Jupyter notebooks for model experimentation
```

---

## Getting Started — For Engineers

### Prerequisites

| Tool | Version | Why |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | >= 1.6 | Provision AWS infrastructure |
| [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) | >= 0.55 | Orchestrate multi-stack Terraform |
| [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | Latest | Authenticate with AWS |
| [Node.js](https://nodejs.org/) | >= 18 | Run frontend & backend services |
| [pnpm](https://pnpm.io/installation) | >= 8 | Package manager for all JS packages |
| [Python](https://www.python.org/downloads/) | >= 3.11 | ML inference scripts, data upload |
| [Make](https://www.gnu.org/software/make/) | >= 4 | Automate all the things |

### Quick Start

```sh
# 1. Clone & enter
git clone <repo-url>
cd earth-overwatch

# 2. (Optional) Deploy infrastructure
make app init    # Initialize all app Terraform stacks
make mlpipe init # Initialize all ML Terraform stacks
make app up      # Provision everything on AWS
make mlpipe up   # Deploy SageMaker models & endpoints

# 3. Start the frontend
make web init    # pnpm install
make web up      # Vite dev server at http://localhost:5173
```

### Makefile Reference

```
make <target> [subtarget] <command>
```

| Command | Description | Targets |
|---|---|---|
| `init` | Initialize Terraform / install deps | app, mlpipe, web |
| `plan` | Preview infrastructure changes | app, mlpipe |
| `up` | Apply infrastructure / start dev server | app, mlpipe, web |
| `down` | Destroy infrastructure | app, mlpipe |
| `build` | Type-check & production-build | web |

**Examples:**

```sh
make app up                    # Deploy ALL app stacks
make app dataplatform up       # Deploy just the dataplatform stack
make app components/landfills up  # Deploy just the landfills stack
make mlpipe aimodels/landfill up  # Deploy ML models
make web build                 # vue-tsc + vite build
make clean                     # Run scripts/cleanup.sh
make dbconn                    # SSH tunnel to Aurora via Bastion
```

### Developing the Frontend

```sh
cd web
pnpm dev        # Hot-reload dev server
pnpm build      # Type-check + production build
pnpm preview    # Preview production build locally
pnpm gen:landfills  # Regenerate TypeScript client from OpenAPI spec
```

The frontend is a **Vue 3 SPA** with:
- **Leaflet** map with satellite & street tile layers
- **Region → Municipality → Zone** drill-down interaction
- **Quasar** UI framework for consistent components
- **Pinia** for state management, **Vue Router** for navigation
- Auto-generated **TypeScript API clients** from OpenAPI specs

### Developing Backend Services

Each API service (`geo`, `monitor`, `detections`) is a standalone Express app:

```sh
cd app/stacks/components/landfills/api-services/detections
pnpm dev        # Local Express server (ts-node)
pnpm build      # esbuild → Lambda deployment bundle
pnpm gen:types  # Regenerate types from OpenAPI spec
```

### Working with ML Models

Model inference code lives in `mlpipe/stacks/aimodels/landfill/`:

- `yolo/` — YOLO11m inference container (PyTorch 2.4 CPU)
- `detr50/` — DETR50 inference container (HuggingFace transformers)

Build and package for SageMaker:
```sh
# Each model has a build.sh that creates model.tar.gz and uploads to S3
cd mlpipe/stacks/aimodels/landfill/yolo
./build.sh
```

Jupyter notebooks for experimentation are in `scripts/notebooks/`.

### Database

The system uses **Aurora Serverless PostgreSQL 16.3 with PostGIS**. To connect locally:

```sh
make dbconn   # Opens SSH tunnel through Bastion host
```

For the initial geo-data load (Italian regions & municipalities):

```sh
cd scripts/build-geo-db
python upload_to_db.py          # Upload municipalities
python upload_to_db_region.py   # Upload regions
```

---

## Contributing

### Code Conventions

- **Commits** follow [gitmoji](https://gitmoji.dev/) for semantic clarity (e.g., `:sparkles:` for features, `:bug:` for fixes, `:alembic:` for experiments)
- **OpenAPI-first** — API contracts are defined in `openapi.yaml` specs; TypeScript clients and types are auto-generated
- **Frontend** follows Vue 3 Composition API with `<script setup lang="ts">`
- **Backend** Express routes are validated with Zod schemas
- **Infrastructure** uses Terragrunt with a shared `common.hcl` for remote state, provider, and backend config

### Pull Request Workflow

1. Branch from `main` with a descriptive name (`feature/`, `fix/`, `experiment/`)
2. Make your changes following existing conventions
3. Run relevant builds:
   - Frontend: `make web build`
   - Backend: `pnpm build` in the service directory
   - Infrastructure: `make app plan` to preview changes
4. Open a PR with a clear description of what and why

### Cleanup

Before opening a PR, clean up any temporary resources:

```sh
make clean     # Stops notebook instances, deletes unused API stages
```

---

## License

This project is part of a thesis work by S. Cirone.
