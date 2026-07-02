const Chat = require('../models/Chat');
const User = require('../models/User');

/**
 * @desc    Create or get a 1-to-1 chat
 * @route   POST /api/chats
 * @access  Private
 */
const accessChat = async (req, res, next) => {
  const { userId } = req.body;

  if (!userId) {
    res.status(400);
    return next(new Error('userId param not sent with request'));
  }

  try {
    // Check if chat exists
    let isChat = await Chat.find({
      isGroup: false,
      $and: [
        { participants: { $elemMatch: { $eq: req.user._id } } },
        { participants: { $elemMatch: { $eq: userId } } },
      ],
    })
      .populate('participants', '-password')
      .populate('lastMessage');

    // Populate sender details inside lastMessage
    isChat = await User.populate(isChat, {
      path: 'lastMessage.sender',
      select: 'username email avatarUrl isOnline lastSeen',
    });

    if (isChat.length > 0) {
      res.send(isChat[0]);
    } else {
      // Create new chat
      const chatData = {
        isGroup: false,
        participants: [req.user._id, userId],
      };

      const createdChat = await Chat.create(chatData);
      const fullChat = await Chat.findOne({ _id: createdChat._id }).populate(
        'participants',
        '-password'
      );
      res.status(201).json(fullChat);
    }
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get all chats for a user
 * @route   GET /api/chats
 * @access  Private
 */
const getChats = async (req, res, next) => {
  try {
    let chats = await Chat.find({
      participants: { $elemMatch: { $eq: req.user._id } },
    })
      .populate('participants', '-password')
      .populate('lastMessage')
      .sort({ updatedAt: -1 });

    chats = await User.populate(chats, {
      path: 'lastMessage.sender',
      select: 'username email avatarUrl isOnline lastSeen',
    });

    res.json(chats);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  accessChat,
  getChats,
};
