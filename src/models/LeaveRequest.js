const mongoose = require("mongoose");

const leaveRequestSchema = new mongoose.Schema(
  {
    student_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "StudentProfile",
      required: true,
    },

    leave_type: {
      type: String,
      required: true,
    },

    start_date: {
      type: Date,
      required: true,
    },

    end_date: {
      type: Date,
      required: true,
    },

    reason: {
      type: String,
      required: true,
    },

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
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("LeaveRequest", leaveRequestSchema);
