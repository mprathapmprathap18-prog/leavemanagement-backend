const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

// DB
const db = mysql.createConnection(process.env.MYSQL_PUBLIC_URL);

db.connect(err => {
  if (err) console.log(err);
  else console.log("DB Connected");
});

/* ================= LOGIN ================= */
app.post("/login", (req, res) => {
  const { username, password } = req.body;

  db.query(
    "SELECT * FROM users WHERE username=? AND password=?",
    [username, password],
    (err, result) => {
      if (err) return res.send(err);
      if (result.length > 0) res.json(result[0]);
      else res.status(401).json({ message: "Invalid" });
    }
  );
});

/* ================= APPLY LEAVE ================= */
app.post("/apply-leave", (req, res) => {
  const { student_id, reason } = req.body;

  db.query(
    "INSERT INTO leave_requests (student_id, reason) VALUES (?,?)",
    [student_id, reason],
    (err) => {
      if (err) return res.send(err);
      res.send("Applied");
    }
  );
});

/* ================= STUDENT STATUS ================= */
app.get("/api/leaves/student/:id", (req, res) => {
  db.query(
    "SELECT * FROM leave_requests WHERE student_id=?",
    [req.params.id],
    (err, result) => res.json(result)
  );
});

/* ================= MANAGER LIST ================= */
app.get("/manager/:id", (req, res) => {
  db.query(
    `SELECT lr.*, sp.name, sp.dept
     FROM leave_requests lr
     JOIN student_profile sp ON lr.student_id = sp.id
     WHERE sp.manager_id=?`,
    [req.params.id],
    (err, result) => res.json(result)
  );
});

/* ================= MANAGER APPROVE ================= */
app.put("/api/leaves/manager/approve/:id", (req, res) => {
  db.query(
    "UPDATE leave_requests SET manager_status='approved' WHERE id=?",
    [req.params.id],
    (err) => res.send("Manager Approved")
  );
});

/* ================= MANAGER REJECT ================= */
app.put("/api/leaves/manager/reject/:id", (req, res) => {
  db.query(
    "UPDATE leave_requests SET manager_status='rejected', final_status='rejected' WHERE id=?",
    [req.params.id],
    (err) => res.send("Manager Rejected")
  );
});

/* ================= TUTOR LIST ================= */
app.get("/tutor/:id", (req, res) => {
  db.query(
    `SELECT lr.*, sp.name, sp.dept
     FROM leave_requests lr
     JOIN student_profile sp ON lr.student_id = sp.id
     WHERE sp.tutor_id=? AND lr.manager_status='approved'`,
    [req.params.id],
    (err, result) => res.json(result)
  );
});

/* ================= TUTOR APPROVE ================= */
app.put("/api/leaves/tutor/approve/:id", (req, res) => {
  db.query(
    "UPDATE leave_requests SET tutor_status='approved', final_status='approved' WHERE id=?",
    [req.params.id],
    (err) => res.send("Tutor Approved")
  );
});

/* ================= TUTOR REJECT ================= */
app.put("/api/leaves/tutor/reject/:id", (req, res) => {
  db.query(
    "UPDATE leave_requests SET tutor_status='rejected', final_status='rejected' WHERE id=?",
    [req.params.id],
    (err) => res.send("Tutor Rejected")
  );
});

/* ================= SERVER ================= */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log("Server running"));
