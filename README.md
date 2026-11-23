# FitStudio

FitStudio is our CS 157A class booking app. Use this guide to rehearse **Step 4 (successful booking)** and **Step 5 (two users competing for the last seat)**.

## Set up before the demo

1. Start PostgreSQL. In pgAdmin, create an empty database called `fitstudio` and open its Query Tool.
2. Run these files in order on that database:
   - [01_create_tables.sql](sql/01_create_tables.sql)
   - [02_seed_data.sql](sql/02_seed_data.sql)
   - [03_demo_setup.sql](sql/03_demo_setup.sql) creates future classes 201 and 202.
3. From the repo folder in VS Code, run:

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp db.ini.example db.ini
```

4. Set your local PostgreSQL username and password in `db.ini`. If you used a different database name or port, set those too.
5. Run `.venv/bin/python app.py` in **two terminals** from the repo folder. Both should say `Connected to fitstudio` and show the menu. Open [demo.sql](sql/demo.sql) in pgAdmin on that same database. Highlight only the query for the step you’re showing before running it.

For another full rehearsal, use a fresh empty database and repeat the SQL setup. Set `dbname` in `db.ini` to the new database.

## Step 4: Successful booking

1. In terminal A, choose **3 — Book class**. Enter member **1**, pass **2**, and class **201**.
2. Answer **n** to the pause prompt. Show **Committed.**
3. Run the **Step 4** SELECT in `demo.sql`. It shows class **201** as **BOOKED** and the pass balance at **4**. The pass started with **5** credits.

## Step 5: Two users compete for the last seat

1. In terminal A, choose **3**. Enter member **1**, pass **2**, class **202**, and answer **y**. Wait for **Booking pending** and leave A at that prompt.
2. In terminal B, choose **3**. Enter member **3**, pass **1**, class **202**, and answer **n**. Show that B is still waiting.
3. Press **Enter** in terminal A to commit. A shows **Committed.** and B shows **Rejected: This class is full**.
4. Run the **Step 5** SELECT in `demo.sql`. It should show class **202**, capacity **1**, and **1** booked seat.
