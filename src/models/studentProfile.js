const mongoose = require("mongoose");

const studentProfileSchema = new mongoose.Schema({
  user_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  name: String,
  dept: String,
  year: String,
  college: String,
  hostel_name: String,
  manager_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },
  tutor_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },
});

module.exports = mongoose.model("StudentProfile",studentProfileSchema);
 
