const mongoose = require("mongoose");

const leaveRequestSchema = new mongoose.Schema({
  student_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "StudentProfile",
    required: true,
  },
  leave_type: String,
  start_date: Date,
  end_date: Date,
  reason: String,
  manager_status: {
    type: String,
    default: "PENDING",
  },
  tutor_status: {
    type: String,
    default: "PENDING",
  },
  final_status: {
    type: String,
    default: "PENDING",
  },
  created_at: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model("LeaveRequest", leaveRequestSchema);
