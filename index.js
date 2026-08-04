// server.js - Render Deployment Version
// Connects to Railway MySQL via MYSQL_PUBLIC_URL
const User = require("./src/models/User");
const StudentProfile = require("./src/models/studentProfile");
const LeaveRequest = require("./src/models/LeaveRequest");
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const dotenv = require('dotenv');
const mongoose = require("mongoose");

dotenv.config();

const app = express();

// Middleware
app.use(express.json());
app.use(cors());
// mongoo db
console.log("MONGO_URI =", process.env.MONGO_URI);

mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log("✅ MongoDB Connected!");
    console.log("Database:", mongoose.connection.db.databaseName);
  })
  .catch((err) => {
    console.log("❌ MongoDB Error:", err);
  });

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key_change_in_production';

console.log('🚀 Render Backend Starting');
// ==================== MIDDLEWARE ====================

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid token' });
    req.user = user;
    next();
  });
};

const authorizeRole = (roles) => {
  return (req, res, next) => {

    console.log("USER ROLE:", req.user.role);
    console.log("ALLOWED ROLES:", roles);

    const userRole = req.user.role.toLowerCase();

    const allowedRoles = roles.map(
      role => role.toLowerCase()
    );

    if (!allowedRoles.includes(userRole)) {
      return res.status(403).json({
        error: 'Unauthorized access'
      });
    }

    next();
  };
};
// ==================== AUTH ENDPOINTS ====================

// ==================== AUTH ENDPOINTS ====================

app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        error: "Username and password required"
      });
    }

    // Find user in MongoDB
const allUsers = await User.find();
console.log("===== ALL USERS =====");
console.log(allUsers);

const user = await User.findOne({ username });

console.log("Username entered:", username);
console.log("User found:", user);

    if (!user) {
      return res.status(401).json({
        error: "Invalid username or password"
      });
    }

    // Check password
    console.log("Entered password:", password);
console.log("DB password:", user ? user.password : "No user");
    if (password !== user.password) {
      return res.status(401).json({
        error: "Invalid username or password"
      });
    }

    let userInfo = {
      id: user._id,
      username: user.username,
      role: user.role.toUpperCase()
    };

    // Student Profile
    if (user.role.toUpperCase() === "STUDENT") {
      const student = await StudentProfile.findOne({
       user_id:user._id.toString()
      });

      if (student) {
        userInfo.full_name = student.name;
        userInfo.dept = student.dept;
      }
    }

    // JWT Token
    const token = jwt.sign(
      {
        id: user._id,
        username: user.username,
        role: user.role.toUpperCase()
      },
      JWT_SECRET,
      { expiresIn: "24h" }
    );

    res.json({
      message: "Login successful",
      token,
      user: userInfo
    });

  } catch (error) {
    console.error("Login error:", error);

    res.status(500).json({
      error: error.message
    });
  }
});

// ==================== STUDENT ENDPOINTS ====================

app.post(
  "/api/leaves/submit",
  authenticateToken,
  authorizeRole(["student", "STUDENT"]),
  async (req, res) => {
    try {
      const { leave_type, start_date, end_date, reason } = req.body;

      if (!reason) {
        return res.status(400).json({
          error: "Reason required",
        });
      }

      const student = await StudentProfile.findOne({
        user_id:user._id.toString()
      });

      if (!student) {
        return res.status(404).json({
          error: "Student profile not found",
        });
      }

      const leave = await LeaveRequest.create({
        student_id: student._id,
        leave_type,
        start_date,
        end_date,
        reason,
        manager_status: "PENDING",
        tutor_status: "PENDING",
        final_status: "PENDING",
      });

      res.status(201).json({
        message: "Leave request submitted successfully",
        leave_id: leave._id,
      });

    } catch (error) {
      console.error("Submit leave error:", error);

      res.status(500).json({
        error: error.message,
      });
    }
  }
);

app.get(
  "/api/leaves/my-leaves",
  authenticateToken,
  authorizeRole(["STUDENT"]),
  async (req, res) => {
    try {
      const student = await StudentProfile.findOne({
        user_id: req.user.id,
      });

      if (!student) {
        return res.status(404).json({
          error: "Student profile not found",
        });
      }

      const leaves = await LeaveRequest.find({
        student_id: student._id,
      }).sort({ createdAt: -1 });

      res.json({
        success: true,
        leaves,
      });

    } catch (error) {
      console.log(error);

      res.status(500).json({
        error: error.message,
      });
    }
  }
);
// ==================== MANAGER ENDPOINTS ====================

// ==================== MANAGER ENDPOINTS ====================

app.get(
  "/api/manager/pending-leaves",
  authenticateToken,
  authorizeRole(["MANAGER"]),
  async (req, res) => {
    try {

      const students = await StudentProfile.find({
  manager_id:user._id.tostring()
});

const studentIds = students.map(s => s._id);

const leaves = await LeaveRequest.find({
  student_id: { $in: studentIds },
  manager_status: "PENDING"
}).populate("student_id");

      res.json({
        message: "Pending leaves retrieved",
        leaves
      });

    } catch (error) {
      console.error("Get pending leaves error:", error);

      res.status(500).json({
        error: error.message
      });
    }
  }
);

app.post(
  "/api/manager/approve-leave/:leaveId",
  authenticateToken,
  authorizeRole(["MANAGER"]),
  async (req, res) => {
    try {

      const { leaveId } = req.params;
      const { status } = req.body;

      if (!["APPROVED", "REJECTED"].includes(status)) {
        return res.status(400).json({
          error: "Invalid status"
        });
      }

      const leave = await LeaveRequest.findByIdAndUpdate(
        leaveId,
        {
          manager_status: status
        },
        {
          new: true
        }
      );

      if (!leave) {
        return res.status(404).json({
          error: "Leave not found"
        });
      }

      res.json({
        message: `Leave ${status.toLowerCase()} by manager`,
        leave_id: leave._id
      });

    } catch (error) {
      console.error("Approve leave error:", error);

      res.status(500).json({
        error: error.message
      });
    }
  }
);

// ==================== TUTOR ENDPOINTS ====================

app.get(
  "/api/tutor/pending-leaves",
  authenticateToken,
  authorizeRole(["TUTOR"]),
  async (req, res) => {
    try {

      const students = await StudentProfile.find({
        tutor_id:user._id.tostring()
      });

      const studentIds = students.map(s => s._id);

      const leaves = await LeaveRequest.find({
        student_id: { $in: studentIds },
        manager_status: "APPROVED",
        tutor_status: "PENDING"
      }).populate("student_id");

      res.json({
        message: "Pending leaves for tutor approval",
        leaves
      });

    } catch (error) {

      console.error("Get tutor leaves error:", error);

      res.status(500).json({
        error: error.message
      });
    }
  }
);

app.post(
  "/api/tutor/approve-leave/:leaveId",
  authenticateToken,
  authorizeRole(["TUTOR"]),
  async (req, res) => {
    try {

      const { leaveId } = req.params;
      const { status } = req.body;

      if (!["APPROVED", "REJECTED"].includes(status)) {
        return res.status(400).json({
          error: "Invalid status"
        });
      }

      const finalStatus =
        status === "APPROVED" ? "APPROVED" : "REJECTED";

      const leave = await LeaveRequest.findByIdAndUpdate(
        leaveId,
        {
          tutor_status: status,
          final_status: finalStatus
        },
        {
          new: true
        }
      );

      if (!leave) {
        return res.status(404).json({
          error: "Leave not found"
        });
      }

      res.json({
        message: `Leave ${status.toLowerCase()} by tutor (Final)`,
        leave_id: leave._id
      });

    } catch (error) {

      console.error("Tutor approve leave error:", error);

      res.status(500).json({
        error: error.message
      });
    }
  }
);

// ==================== HEALTH CHECK ====================

app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'Server is running on Render',
    timestamp: new Date()
  });
});

// ==================== START SERVER ====================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`🍃 Using MongoDB Atlas`);
  console.log(`🔐 JWT authentication enabled`);
});

module.exports = app;
