const mongoose = require("mongoose");

const studentProfileSchema = new mongoose.Schema({
  user_id: {
    type: String,
    required: true,
  },

  name: String,

  dept: String,

  year: String,

  college: String,

  hostel_name: String,

  manager_id: {
    type: String,
  },

  tutor_id: {
    type: String,
  },
});

module.exports = mongoose.model("StudentProfile", studentProfileSchema);
