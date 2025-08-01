# Salewise Next.js Frontend

## Overview
This is the Next.js frontend for the Salewise project that generates UI components from Odoo models.

## Tech Stack

### Core Framework
- **Framework**: Next.js 15 with App Router
- **Language**: TypeScript (strict mode)
- **Image Optimization**: next/image

### UI & Styling
- **Component Library**: shadcn/ui
- **Styling**: Tailwind CSS v4
- **Animations**: Framer Motion
- **Themes**: next-themes (dark mode support)

### State Management & Data Fetching
- **Global State**: Zustand
- **Server State**: @tanstack/react-query
- **Persistence**: TanStack Query persistence adapter
- **Tables**: @tanstack/react-table
- **Virtual Scrolling**: @tanstack/react-virtual

### Forms & Validation
- **Forms**: react-hook-form
- **Validation**: Zod
- **Form Resolvers**: @hookform/resolvers

### Authentication & Security
- **Auth**: NextAuth.js
- **Error Tracking**: @sentry/nextjs

### Data Visualization & Content
- **Charts**: Recharts
- **Maps**: Leaflet + react-leaflet + leaflet.markercluster
- **Calendar**: react-big-calendar
- **Rich Text Editor**: @tiptap/react
- **File Upload**: react-dropzone
- **Spreadsheets**: SheetJS

### Utilities
- **Date Handling**: date-fns
- **Internationalization**: next-intl
- **Email Templates**: react-email
- **Analytics**: PostHog

## Project Structure
```
app/
  (dashboard)/        # Dashboard routes group
    layout.tsx        # Dashboard layout with sidebar
    page.tsx          # Main dashboard
    [model]/          # Dynamic routes for each Odoo model
      page.tsx        # List view
      [id]/           # Detail/edit views
        page.tsx
  api/                # API route handlers if needed
  
components/
  ui/                 # shadcn/ui components
  generated/          # Script-generated components
    [model]/          # Components for each Odoo model
      form.tsx        # Generated form component
      list.tsx        # Generated list component
      fields/         # Field-specific components
  odoo/               # Odoo-specific utilities
    json-rpc.ts       # JSON-RPC client
    types.ts          # Generated TypeScript types

lib/
  odoo-client.ts      # Odoo API client wrapper
  utils.ts            # Utility functions

scripts/
  generate.ts         # Main generation script
  templates/          # Component templates
```

## Coding Standards

### Components
- Use function components with TypeScript
- Prefer Server Components (default)
- Use "use client" only when needed (forms, interactivity)
- Follow shadcn/ui patterns for consistency

### State Management
- Server Components for data fetching
- Zustand for global client state
- TanStack Query for server state caching
- Form state with react-hook-form
- Persist query cache with TanStack Query persistence adapter

### API Calls
```typescript
// Always use the typed client
import { odooClient } from '@/lib/odoo-client'

// Server Components
async function ServerComponent() {
  const data = await odooClient.read('res.partner', [1, 2, 3])
  return <div>{/* render data */}</div>
}

// Client Components with TanStack Query
const { data } = useQuery({
  queryKey: ['partners', filters],
  queryFn: () => odooClient.search('res.partner', filters)
})
```

### Generated Components
- Generated files go in `components/generated/[model]/`
- Include a header comment: `// Generated from Odoo model: [model_name]`
- Make components fully typed with generated interfaces
- Keep generation idempotent (safe to re-run)

### Form Handling
```typescript
// Use react-hook-form with zod
const form = useForm<PartnerFormData>({
  resolver: zodResolver(partnerSchema),
  defaultValues: await fetchDefaults()
})
```

## CRM UI Components to Generate

### Contact Management (`res.partner`)
- **List View**: Searchable table with filters (customer/vendor)
- **Detail View**: Tabbed interface (General, Sales, Accounting, etc.)
- **Form**: Address fields, contact info, tags
- **Quick Create**: Modal for rapid contact creation

### Lead & Opportunity Management (`crm.lead`)
- **Kanban Board**: Drag-drop between pipeline stages
- **List View**: Filterable by stage, salesperson, probability
- **Detail View**: Activity timeline, notes, attachments
- **Conversion Wizard**: Lead to opportunity conversion

### Sales Orders (`sale.order`)
- **List View**: Status badges, total amounts, customer info
- **Form**: Line items with product search, pricing, taxes
- **PDF Preview**: Quote/order preview
- **Actions**: Confirm sale, create invoice buttons

### Invoicing (`account.move`)
- **List View**: Payment status, due dates, amounts
- **Form**: Invoice lines, payment terms, taxes
- **Payment Recording**: Quick payment entry modal
- **Bulk Actions**: Send reminders, mark as paid

### Project Management (`project.project` & `project.task`)
- **Project Dashboard**: Progress, team members, timeline
- **Task Kanban**: Drag-drop task management
- **Gantt Chart**: Timeline visualization
- **Time Tracking**: Start/stop timers on tasks

### Employee Directory (`hr.employee`)
- **Grid View**: Photo cards with contact info
- **Org Chart**: Interactive hierarchy visualization
- **Profile View**: Skills, departments, contact details

### Dashboard Components
- **Sales Pipeline**: Funnel visualization
- **Revenue Charts**: Monthly/quarterly trends
- **Activity Feed**: Recent actions across all modules
- **KPI Cards**: Key metrics with sparklines

## Generation Script

### What It Should Do
1. Connect to Odoo via JSON-RPC
2. Introspect model fields and metadata
3. Generate TypeScript interfaces
4. Create form components with proper field types
5. Create list views with sorting/filtering
6. Map Odoo field types to shadcn/ui components:
   - char → Input
   - text → Textarea
   - selection → Select
   - many2one → Combobox
   - boolean → Checkbox
   - date/datetime → DatePicker

### Field Mapping
```typescript
const fieldTypeMap = {
  'char': 'input',
  'text': 'textarea',
  'integer': 'number-input',
  'float': 'number-input',
  'boolean': 'checkbox',
  'selection': 'select',
  'many2one': 'combobox',
  'one2many': 'table',
  'many2many': 'multi-select',
  'date': 'date-picker',
  'datetime': 'datetime-picker'
}
```

## Common Patterns

### Loading States
```typescript
if (isLoading) return <TableSkeleton />
if (error) return <ErrorAlert error={error} />
```

### Error Handling
- Show user-friendly error messages
- Log errors to Sentry in production
- Use toast notifications for actions
- Implement retry mechanisms with TanStack Query

### Tables with TanStack Table
```typescript
const table = useReactTable({
  data,
  columns,
  getCoreRowModel: getCoreRowModel(),
  getPaginationRowModel: getPaginationRowModel(),
  getSortedRowModel: getSortedRowModel(),
})
```

### File Handling
```typescript
// File uploads with react-dropzone
const { getRootProps, getInputProps } = useDropzone({
  onDrop: acceptedFiles => handleFiles(acceptedFiles)
})

// Excel processing with SheetJS
import * as XLSX from 'xlsx'
const workbook = XLSX.read(data, { type: 'buffer' })
```

### Rich Content
```typescript
// Calendar views with react-big-calendar
import { Calendar, momentLocalizer } from 'react-big-calendar'

// Rich text with Tiptap
import { useEditor } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
```

### Maps Integration
```typescript
// Leaflet for location fields
import { MapContainer, TileLayer, Marker } from 'react-leaflet'
import MarkerClusterGroup from 'react-leaflet-cluster'
```

### Performance
- Use React.lazy for code splitting
- Implement virtual scrolling with @tanstack/react-virtual
- Debounce search inputs
- Cache API responses with TanStack Query
- Optimize images with next/image
- Track performance with PostHog

## Testing
- Component tests for generated UI
- Integration tests for Odoo communication
- Type checking with `tsc --noEmit`

## Additional Patterns

### Authentication with NextAuth.js
```typescript
// Configure in app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'

// Protect routes with middleware
export { auth as middleware } from '@/auth'
```

### Global State with Zustand
```typescript
// stores/ui-store.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export const useUIStore = create(persist(
  (set) => ({
    sidebarOpen: true,
    toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen }))
  }),
  { name: 'ui-store' }
))
```

### Internationalization
```typescript
// With next-intl
import { useTranslations } from 'next-intl'
const t = useTranslations('Partners')
```

### Email Templates
```typescript
// With react-email
import { Button, Html, Text } from '@react-email/components'
export const WelcomeEmail = ({ name }) => (
  <Html>
    <Text>Welcome {name}!</Text>
    <Button href="...">Get Started</Button>
  </Html>
)
```

## Security
- Never store Odoo credentials in frontend
- Use environment variables for API endpoints
- Implement CSRF protection with NextAuth.js
- Validate all inputs client and server side
- Track errors and security events with Sentry

---
*This document is specific to the Next.js frontend implementation*