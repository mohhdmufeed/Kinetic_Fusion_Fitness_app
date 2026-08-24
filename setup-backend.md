# Backend Setup Instructions

Use this guide to set up the backend for this project using **Supabase**, **Drizzle ORM**, and **Next.js Server Actions**.

This guide is split into two configurations:
- **Part 1: Online Setup (Supabase Cloud)**
- **Part 2: Offline / Local Development Setup (Supabase CLI / Local Postgres)**
- **Part 3: Project Setup & Code Implementation (Shared)**

---

## Helpful Links
- [Supabase Docs](https://supabase.com/docs)
- [Drizzle Docs](https://orm.drizzle.team/docs/overview)
- [Drizzle with Supabase Quickstart](https://orm.drizzle.team/learn/tutorials/drizzle-with-supabase)
- [Supabase CLI Local Development](https://supabase.com/docs/guides/local-development)

---

## Install Libraries

Install the required dependencies in your Next.js project:

```bash
npm i drizzle-orm dotenv postgres
npm i -D drizzle-kit
```

---

## Environment Configuration

### Option A: Online Version (Supabase Cloud)

1. Create a project at [supabase.com](https://supabase.com/).
2. Go to **Project Settings** > **Database** > **Connection string**.
3. Use the **Transaction Pooler** connection string (recommended for Serverless / Next.js) or Direct Connection string.
4. Create `.env.local` in your root directory:

```env
# Supabase Cloud Database URL (Direct or Transaction Pooler via port 6543/5432)
DATABASE_URL="postgresql://postgres.[PROJECT-REF]:[YOUR-PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres"

# Optional Supabase API keys (if client SDK is needed)
NEXT_PUBLIC_SUPABASE_URL="https://[PROJECT-REF].supabase.co"
NEXT_PUBLIC_SUPABASE_ANON_KEY="your-anon-key"
```

---

### Option B: Offline / Local Version (Supabase CLI & Local Postgres)

1. Install Supabase CLI (if not already installed):
   ```bash
   npm i -D supabase
   ```
2. Initialize Supabase in your project:
   ```bash
   npx supabase init
   ```
3. Start the local Supabase container (requires Docker):
   ```bash
   npx supabase start
   ```
4. Create `.env.local` in your root directory pointing to the local postgres instance:

```env
# Local Supabase Postgres Connection URL
DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"

# Local Supabase API keys (output by `supabase start`)
NEXT_PUBLIC_SUPABASE_URL="http://127.0.0.1:54321"
NEXT_PUBLIC_SUPABASE_ANON_KEY="your-local-anon-key"
```

> **Local Studio**: You can view and manage your local database table interface at `http://127.0.0.1:54323`.

---

## Setup Steps

### 1. Folder Structure
- [ ] Create `/db` folder in the root of the project
- [ ] Create `/db/schema` folder
- [ ] Create `/db/queries` folder
- [ ] Create `/types` folder in the root of the project
- [ ] Create `/types/actions` folder
- [ ] Create `/actions` folder in the root of the project

---

### 2. Drizzle Configuration

- [ ] Add `drizzle.config.ts` to the root of the project:

```ts
import { config } from "dotenv";
import { defineConfig } from "drizzle-kit";

config({ path: ".env.local" });

export default defineConfig({
  schema: "./db/schema/index.ts",
  out: "./db/migrations",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL!
  }
});
```

---

### 3. Database Connection Client

- [ ] Create `db/db.ts`:

```ts
import { config } from "dotenv";
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as schema from "./schema";

config({ path: ".env.local" });

const client = postgres(process.env.DATABASE_URL!);

export const db = drizzle(client, { schema });
```

---

### 4. Database Schemas

- [ ] Create `db/schema/example-schema.ts`:

```ts
import { integer, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const exampleTable = pgTable("example", {
  id: uuid("id").defaultRandom().primaryKey(),
  name: text("name").notNull(),
  age: integer("age").notNull(),
  email: text("email").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at")
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date())
});

export type InsertExample = typeof exampleTable.$inferInsert;
export type SelectExample = typeof exampleTable.$inferSelect;
```

- [ ] Create `db/schema/index.ts` to export all schemas:

```ts
export * from "./example-schema";
```

---

### 5. Queries Layer

- [ ] Create `db/queries/example-queries.ts`:

```ts
"use server";

import { eq } from "drizzle-orm";
import { db } from "../db";
import { exampleTable, InsertExample, SelectExample } from "../schema/example-schema";

export const createExample = async (data: InsertExample) => {
  try {
    const [newExample] = await db.insert(exampleTable).values(data).returning();
    return newExample;
  } catch (error) {
    console.error("Error creating example:", error);
    throw new Error("Failed to create example");
  }
};

export const getExampleById = async (id: string) => {
  try {
    const example = await db.query.exampleTable.findFirst({
      where: eq(exampleTable.id, id)
    });
    if (!example) {
      throw new Error("Example not found");
    }
    return example;
  } catch (error) {
    console.error("Error getting example by ID:", error);
    throw new Error("Failed to get example");
  }
};

export const getAllExamples = async (): Promise<SelectExample[]> => {
  return db.query.exampleTable.findMany();
};

export const updateExample = async (id: string, data: Partial<InsertExample>) => {
  try {
    const [updatedExample] = await db
      .update(exampleTable)
      .set(data)
      .where(eq(exampleTable.id, id))
      .returning();
    return updatedExample;
  } catch (error) {
    console.error("Error updating example:", error);
    throw new Error("Failed to update example");
  }
};

export const deleteExample = async (id: string) => {
  try {
    await db.delete(exampleTable).where(eq(exampleTable.id, id));
  } catch (error) {
    console.error("Error deleting example:", error);
    throw new Error("Failed to delete example");
  }
};
```

---

### 6. Migrations Setup & Execution

- [ ] In `package.json`, add the following scripts:

```json
"scripts": {
  "db:generate": "npx drizzle-kit generate",
  "db:migrate": "npx drizzle-kit migrate"
}
```

- [ ] Generate migration SQL files:
  ```bash
  npm run db:generate
  ```

- [ ] Run migration against the target database (Cloud or Local based on `.env.local`):
  ```bash
  npm run db:migrate
  ```

---

### 7. Types Definition

- [ ] Create `types/actions/action-types.ts`:

```ts
export type ActionState<T = any> = {
  status: "success" | "error";
  message: string;
  data?: T;
};
```

- [ ] Create `types/index.ts`:

```ts
export * from "./actions/action-types";
```

---

### 8. Server Actions

- [ ] Create `actions/example-actions.ts`:

```ts
"use server";

import {
  createExample,
  deleteExample,
  getAllExamples,
  getExampleById,
  updateExample
} from "@/db/queries/example-queries";
import { InsertExample, SelectExample } from "@/db/schema/example-schema";
import { ActionState } from "@/types";
import { revalidatePath } from "next/cache";

export async function createExampleAction(data: InsertExample): Promise<ActionState<SelectExample>> {
  try {
    const newExample = await createExample(data);
    revalidatePath("/examples");
    return { status: "success", message: "Example created successfully", data: newExample };
  } catch (error) {
    return { status: "error", message: "Failed to create example" };
  }
}

export async function getExampleByIdAction(id: string): Promise<ActionState<SelectExample>> {
  try {
    const example = await getExampleById(id);
    return { status: "success", message: "Example retrieved successfully", data: example };
  } catch (error) {
    return { status: "error", message: "Failed to get example" };
  }
}

export async function getAllExamplesAction(): Promise<ActionState<SelectExample[]>> {
  try {
    const examples = await getAllExamples();
    return { status: "success", message: "Examples retrieved successfully", data: examples };
  } catch (error) {
    return { status: "error", message: "Failed to get examples" };
  }
}

export async function updateExampleAction(
  id: string,
  data: Partial<InsertExample>
): Promise<ActionState<SelectExample>> {
  try {
    const updatedExample = await updateExample(id, data);
    revalidatePath("/examples");
    return { status: "success", message: "Example updated successfully", data: updatedExample };
  } catch (error) {
    return { status: "error", message: "Failed to update example" };
  }
}

export async function deleteExampleAction(id: string): Promise<ActionState<void>> {
  try {
    await deleteExample(id);
    revalidatePath("/examples");
    return { status: "success", message: "Example deleted successfully" };
  } catch (error) {
    return { status: "error", message: "Failed to delete example" };
  }
}
```

---

### 9. Verification & Manual Testing Page

- [ ] Implement server actions test interface in `app/page.tsx`:

```tsx
"use client";

import { useState, useTransition } from "react";
import {
  createExampleAction,
  getAllExamplesAction,
  deleteExampleAction
} from "@/actions/example-actions";

export default function Home() {
  const [name, setName] = useState("");
  const [age, setAge] = useState<number>(25);
  const [email, setEmail] = useState("");
  const [items, setItems] = useState<any[]>([]);
  const [message, setMessage] = useState("");
  const [isPending, startTransition] = useTransition();

  const handleFetch = () => {
    startTransition(async () => {
      const res = await getAllExamplesAction();
      if (res.status === "success" && res.data) {
        setItems(res.data);
      }
      setMessage(res.message);
    });
  };

  const handleCreate = () => {
    startTransition(async () => {
      const res = await createExampleAction({ name, age: Number(age), email });
      setMessage(res.message);
      if (res.status === "success") {
        setName("");
        setEmail("");
        handleFetch();
      }
    });
  };

  const handleDelete = (id: string) => {
    startTransition(async () => {
      const res = await deleteExampleAction(id);
      setMessage(res.message);
      handleFetch();
    });
  };

  return (
    <main style={{ maxWidth: 600, margin: "40px auto", fontFamily: "sans-serif" }}>
      <h1>Backend Setup Verification</h1>
      {message && <p style={{ padding: 8, background: "#f0f0f0" }}>{message}</p>}

      <section style={{ marginBottom: 24, display: "flex", flexDirection: "column", gap: 8 }}>
        <h2>Create Item</h2>
        <input
          placeholder="Name"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <input
          placeholder="Age"
          type="number"
          value={age}
          onChange={(e) => setAge(Number(e.target.value))}
        />
        <input
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
        <button onClick={handleCreate} disabled={isPending}>
          {isPending ? "Submitting..." : "Create Example"}
        </button>
      </section>

      <section>
        <h2>Existing Items</h2>
        <button onClick={handleFetch} disabled={isPending}>
          Load All Items
        </button>
        <ul>
          {items.map((item) => (
            <li key={item.id} style={{ margin: "8px 0" }}>
              <strong>{item.name}</strong> ({item.age}) - {item.email}
              <button
                onClick={() => handleDelete(item.id)}
                style={{ marginLeft: 12, color: "red" }}
                disabled={isPending}
              >
                Delete
              </button>
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}
```
