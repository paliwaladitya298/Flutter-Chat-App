const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema(
  {
    participants: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
      },
    ],
    isGroup: {
      type: Boolean,
      default: false,
    },
    lastMessage: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Message',
    },
  },
  {
    timestamps: true,
  }
);

// Optional: ensure unique conversation for 1-to-1 chats
// Wait, we can handle duplicate checks in the controller, 
// but adding indexing makes it fast.

const Chat = mongoose.model('Chat', chatSchema);
module.exports = Chat;
