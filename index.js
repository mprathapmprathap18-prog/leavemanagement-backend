const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

// DB connection
const db = mysql.createConnection({
  host: "YOUR_HOST",
  user: "YOUR_USER",
  password: "YOUR_PASSWORD",
  database: "YOUR_DB"
});

db.connect(err => {
  if (err) console.log(err);
  else console.log("DB Connected");
});
//login api//
app.post("/login", (req, res) => {
  const { username, password } = req.body;

  db.query(
    "SELECT * FROM users WHERE username=? AND password=?",
    [username, password],
    (err, result) => {
      if (err) return res.send(err);

      if (result.length > 0) {
        res.json(result[0]);
      } else {
        res.send("Invalid login");
      }
    }
  );
});
//student_profile//
app.get("/api/leaves/student/:id", (req, res) => {
  db.query(
    "SELECT * FROM leave_requests WHERE student_id=?",
    [req.params.id],
    (err, result) => {
      res.json(result);
    }
  );
});
//leave apply api//
app.post("/apply-leave", (req, res) => {
  const { student_id, reason } = req.body;

  db.query(
    "INSERT INTO leave_requests (student_id, reason) VALUES (?, ?)",
    [student_id, reason],
    (err, result) => {
      if (err) return res.send(err);
      res.send("Leave Applied");
    }
  );
});
//manager view//
app.get("/manager/:id", (req, res) => {
  db.query(
    `SELECT lr.*, sp.name, sp.dept, sp.college, sp.year
     FROM leave_requests lr
     JOIN student_profile sp ON lr.student_id = sp.id
     WHERE sp.manager_id = ?`,
    [req.params.id],
    (err, result) => {
      res.json(result);
    }
  );
});
//tutor view//
app.get("/manager/:id", (req, res) => {
  db.query(
    `SELECT lr.*, sp.name, sp.dept, sp.college, sp.year
     FROM leave_requests lr
     JOIN student_profile sp ON lr.student_id = sp.id
     WHERE sp.manager_id = ?`,
    [req.params.id],
    (err, result) => {
      res.json(result);
    }
  );
});
//tutor approve//
app.put("/api/leaves/tutor/approve/:id", (req, res) => {
  db.query(
    "UPDATE leave_requests SET final_status='approved', tutor_status='approved' WHERE id=?",
    [req.params.id]
  );
});
app.listen(3000, () => {
  console.log("Server running");
});
