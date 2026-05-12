// server.js - Render Deployment Version
// Connects to Railway MySQL via MYSQL_PUBLIC_URL
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const jwt = require('jsonwebtoken');
const dotenv = require('dotenv');

dotenv.config();

const app = express();

// Middleware
app.use(express.json());
app.use(cors());

// MySQL Connection Pool - Using Railway MySQL Public URL
const pool = mysql.createPool(process.env.MYSQL_PUBLIC_URL);

(async () => {
  try {
    const conn = await pool.getConnection();
    console.log("✅ MySQL Connected!");
    conn.release();
  } catch (err) {
    console.error("❌ MySQL Error:", err.message);
  }
})();
(async () => {
  try {
    const conn = await pool.getConnection();
    console.log("✅ MySQL Connected!");
    conn.release();
  } catch (err) {
    console.error("❌ MySQL Error:", err.message);
  }
})();

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key_change_in_production';

console.log('🚀 Render Backend Starting');
console.log('📡 Database Config:', {
  host: process.env.MYSQLHOST,
  database: process.env.MYSQLDATABASE,
  port: process.env.MYSQLPORT,
  hasPublicUrl: !!process.env.MYSQL_PUBLIC_URL
});

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

app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }

    const connection = await pool.getConnection();
    
    const [users] = await connection.execute(
      'SELECT id, username, password, role FROM users WHERE username = ?',
      [username]
    );

    if (users.length === 0) {
      connection.release();
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const user = users[0];

    if (password !== user.password) {
      connection.release();
      return res.status(401).json({ error: 'Invalid username or password' });
    }

  let userInfo = {
  id: user.id,
  username: user.username,
  role: user.role.toUpperCase()
};

    if (user.role === 'STUDENT') {
      const [students] = await connection.execute(
        'SELECT id, name, dept FROM student_profile WHERE user_id = ?',
        [user.id]
      );
      if (students.length > 0) {
        userInfo.full_name = students[0].name;
        userInfo.dept = students[0].dept;
      }
    }

    const token = jwt.sign(
  {
    id: user.id,
    username: user.username,
    role: user.role.toUpperCase()
  },
  JWT_SECRET,
  { expiresIn: '24h' }
);

    connection.release();

    res.json({
      message: 'Login successful',
      token,
      user: userInfo
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error: ' + error.message });
  }
});

// ==================== STUDENT ENDPOINTS ====================

app.post('/api/leaves/submit',
 authenticateToken,
 authorizeRole(['student', 'STUDENT']),
 async (req, res) => {
  try {
   const { leave_type, start_date, end_date, reason } = req.body;
    const userId = req.user.id;

    if (!reason) {
      return res.status(400).json({ error: 'Reason required' });
    }

    const connection = await pool.getConnection();

    const [students] = await connection.execute(
      'SELECT id FROM student_profile WHERE user_id = ?',
      [userId]
    );

    if (students.length === 0) {
      connection.release();
      return res.status(404).json({ error: 'Student profile not found' });
    }

    const studentId = students[0].id;

 const [result] = await connection.execute(
  `INSERT INTO leave_requests
  (
    student_id,
    leave_type,
    start_date,
    end_date,
    reason,
    manager_status,
    tutor_status,
    final_status,
    created_at
  )
  VALUES
  (
    ?, ?, ?, ?, ?,
    'PENDING',
    'PENDING',
    'PENDING',
    NOW()
  )`,
  [
    studentId,
    leave_type,
    start_date,
    end_date,
    reason
  ]
);
    connection.release();

    res.status(201).json({
      message: 'Leave request submitted successfully',
      leave_id: result.insertId
    });

  } catch (error) {
    console.error('Submit leave error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});
app.get('/api/leaves/my-leaves',
 authenticateToken,
 authorizeRole(['STUDENT']),
 async (req, res) => {

  try {

    const userId = req.user.id;

    const connection = await pool.getConnection();

    const [students] = await connection.execute(
      'SELECT id FROM student_profile WHERE user_id = ?',
      [userId]
    );

    if (students.length === 0) {
      connection.release();

      return res.status(404).json({
        error: 'Student profile not found'
      });
    }

    const studentId = students[0].id;

    const [leaves] = await connection.execute(
      `SELECT
        leave_requests.id,
        leave_requests.student_id,
        leave_requests.leave_type,
        leave_requests.start_date,
        leave_requests.end_date,
        leave_requests.reason,
        leave_requests.manager_status,
        leave_requests.tutor_status,
        leave_requests.final_status,
        leave_requests.created_at,

        student_profile.name,
        student_profile.dept,
        student_profile.year,
        student_profile.college,
        student_profile.hostel_name

      FROM leave_requests

      JOIN student_profile
      ON leave_requests.student_id = student_profile.id

      WHERE leave_requests.student_id = ?

      ORDER BY leave_requests.created_at DESC`,
      [studentId]
    );

    connection.release();

    res.json({
      success: true,
      leaves: leaves
    });

  } catch (error) {

  console.log("MY LEAVES ERROR:", error);

  res.status(500).json({
    error: error.message
  });
}
});
// ==================== MANAGER ENDPOINTS ====================

app.get('/api/manager/pending-leaves', authenticateToken, authorizeRole(['MANAGER']), async (req, res) => {
  try {
    const userId = req.user.id;
    const connection = await pool.getConnection();

    const [leaves] = await connection.execute(
      `SELECT 
        lr.id, lr.student_id, lr.reason, lr.manager_status, lr.tutor_status, lr.created_at,
        sp.name as student_name, sp.dept, u.username,
        sp.year, sp.college
       FROM leave_requests lr
       JOIN student_profile sp ON lr.student_id = sp.id
       JOIN users u ON sp.user_id = u.id
       WHERE sp.manager_id = ? AND lr.manager_status = 'PENDING'
       ORDER BY lr.created_at ASC`,
      [userId]
    );

    connection.release();

    res.json({
      message: 'Pending leaves retrieved',
      leaves: leaves
    });

  } catch (error) {
    console.error('Get pending leaves error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/api/manager/approve-leave/:leaveId', authenticateToken, authorizeRole(['MANAGER']), async (req, res) => {
  try {
    const { leaveId } = req.params;
    const { status } = req.body;

    if (!['APPROVED', 'REJECTED'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const connection = await pool.getConnection();

    await connection.execute(
      `UPDATE leave_requests 
       SET manager_status = ?
       WHERE id = ?`,
      [status, leaveId]
    );

    connection.release();

    res.json({
      message: `Leave ${status.toLowerCase()} by manager`,
      leave_id: leaveId
    });

  } catch (error) {
    console.error('Approve leave error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ==================== TUTOR ENDPOINTS ====================

app.get('/api/tutor/pending-leaves', authenticateToken, authorizeRole(['TUTOR']), async (req, res) => {
  try {
    const userId = req.user.id;
    const connection = await pool.getConnection();

    const [leaves] = await connection.execute(
      `SELECT 
        lr.id, lr.student_id, lr.reason, lr.manager_status, lr.tutor_status, lr.created_at,
        sp.name as student_name, sp.dept, u.username,
        sp.year, sp.college
       FROM leave_requests lr
       JOIN student_profile sp ON lr.student_id = sp.id
       JOIN users u ON sp.user_id = u.id
       WHERE sp.tutor_id = ? AND lr.manager_status = 'APPROVED' AND lr.tutor_status = 'PENDING'
       ORDER BY lr.created_at ASC`,
      [userId]
    );

    connection.release();

    res.json({
      message: 'Pending leaves for tutor approval',
      leaves: leaves
    });

  } catch (error) {
    console.error('Get tutor leaves error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/api/tutor/approve-leave/:leaveId', authenticateToken, authorizeRole(['TUTOR']), async (req, res) => {
  try {
    const { leaveId } = req.params;
    const { status } = req.body;

    if (!['APPROVED', 'REJECTED'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const connection = await pool.getConnection();

    const finalStatus = status === 'APPROVED' ? 'APPROVED' : 'REJECTED';
    
    await connection.execute(
      `UPDATE leave_requests 
       SET tutor_status = ?, final_status = ?
       WHERE id = ?`,
      [status, finalStatus, leaveId]
    );

    connection.release();

    res.json({
      message: `Leave ${status.toLowerCase()} by tutor (Final)`,
      leave_id: leaveId
    });

  } catch (error) {
    console.error('Tutor approve leave error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

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
console.log(`✅ Render Server running on port ${PORT}`);
console.log(`🌐 Using Railway MySQL with public URL`);
console.log(`🔐 JWT authentication enabled`);
});

module.exports = app;
