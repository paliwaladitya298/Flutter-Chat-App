const Message = require('../models/Message');
const Chat = require('../models/Chat');
const User = require('../models/User');
const { uploadImage } = require('../config/cloudinary');

/**
 * @desc    Send a new message
 * @route   POST /api/messages
 * @access  Private
 */
const sendMessage = async (req, res, next) => {
  const { text, chatId, imageUrl, type } = req.body;

  if (!chatId || (!text && !imageUrl)) {
    res.status(400);
    return next(new Error('Invalid data passed into request'));
  }

  try {
    const newMessage = {
      chatId,
      sender: req.user._id,
      text: text || '',
      imageUrl: imageUrl || '',
      type: type || 'text',
      readBy: [req.user._id],
    };

    let message = await Message.create(newMessage);

    // Populate sender and chat details
    message = await message.populate('sender', 'username email avatarUrl isOnline lastSeen');
    message = await message.populate('chatId');
    message = await User.populate(message, {
      path: 'chatId.participants',
      select: 'username email avatarUrl isOnline lastSeen',
    });

    // Update last message in Chat
    await Chat.findByIdAndUpdate(chatId, { lastMessage: message._id });

    // Retrieve Socket.IO instance
    const io = req.app.get('socketio');
    if (io) {
      // Emit to the chat room
      io.to(chatId.toString()).emit('message_received', message);

      // Also emit to individual participant rooms to trigger chat list updates / unread badge updates
      message.chatId.participants.forEach((participant) => {
        if (participant._id.toString() === req.user._id.toString()) return;
        io.to(participant._id.toString()).emit('message_received', message);
      });
    }

    res.status(201).json(message);
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get all messages for a specific chat
 * @route   GET /api/messages/:chatId
 * @access  Private
 */
const getMessages = async (req, res, next) => {
  const { chatId } = req.params;

  try {
    // Optional: Update all unread messages from other user as read when we open the chat
    await Message.updateMany(
      {
        chatId,
        sender: { $ne: req.user._id },
        isRead: false,
      },
      {
        $set: { isRead: true },
        $addToSet: { readBy: req.user._id },
      }
    );

    const messages = await Message.find({ chatId })
      .populate('sender', 'username email avatarUrl isOnline lastSeen')
      .populate('chatId');

    // Notify other chat participants via socket that messages are read
    const io = req.app.get('socketio');
    if (io) {
      io.to(chatId).emit('messages_marked_read', {
        chatId,
        readBy: req.user._id,
      });
    }

    res.json(messages);
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Upload an image for sharing
 * @route   POST /api/messages/upload
 * @access  Private
 */
const uploadMessageImage = async (req, res, next) => {
  if (!req.file) {
    res.status(400);
    return next(new Error('No image file provided'));
  }

  try {
    const url = await uploadImage(req.file);
    res.json({ imageUrl: url });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  sendMessage,
  getMessages,
  uploadMessageImage,
};
