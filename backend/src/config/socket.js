const socketIO = require('socket.io');
const User = require('../models/User');
const Chat = require('../models/Chat');

// Map to store userId -> socketId
const userSocketMap = new Map();

const initSocket = (server) => {
  const io = socketIO(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  io.on('connection', (socket) => {
    console.log(`Socket Connected: ${socket.id}`);

    // User setup/authentication on connection
    socket.on('setup', async (userData) => {
      if (!userData || !userData._id) return;
      
      socket.join(userData._id);
      userSocketMap.set(userData._id, socket.id);
      
      // Update online status in database
      try {
        await User.findByIdAndUpdate(userData._id, { isOnline: true });
        // Broadcast that this user is online
        socket.broadcast.emit('user_status_change', {
          userId: userData._id,
          isOnline: true,
          lastSeen: new Date(),
        });
      } catch (err) {
        console.error('Socket setup status error:', err);
      }
      
      socket.emit('connected');
      console.log(`User ${userData.username} mapped to socket ${socket.id}`);
    });

    // Join a specific chat room
    socket.on('join_chat', (room) => {
      socket.join(room);
      console.log(`Socket ${socket.id} joined room: ${room}`);
    });

    // Handle typing events
    socket.on('typing', (room) => {
      socket.in(room).emit('typing', room);
    });

    socket.on('stop_typing', (room) => {
      socket.in(room).emit('stop_typing', room);
    });

    // Handle message read/receipts
    socket.on('read_message', async ({ chatId, messageId, readerId }) => {
      try {
        socket.in(chatId).emit('message_read_receipt', { chatId, messageId, readerId });
      } catch (err) {
        console.error('Socket read_message error:', err);
      }
    });

    // Disconnect event
    socket.on('disconnect', async () => {
      console.log(`Socket Disconnected: ${socket.id}`);
      
      // Find userId for this socketId
      let disconnectedUserId = null;
      for (const [userId, socketId] of userSocketMap.entries()) {
        if (socketId === socket.id) {
          disconnectedUserId = userId;
          break;
        }
      }

      if (disconnectedUserId) {
        userSocketMap.delete(disconnectedUserId);
        try {
          const lastSeen = new Date();
          await User.findByIdAndUpdate(disconnectedUserId, { 
            isOnline: false, 
            lastSeen 
          });
          // Broadcast that user is offline
          io.emit('user_status_change', {
            userId: disconnectedUserId,
            isOnline: false,
            lastSeen,
          });
          console.log(`User ${disconnectedUserId} went offline`);
        } catch (err) {
          console.error('Socket disconnect status error:', err);
        }
      }
    });
  });

  return io;
};

// Helper function to send messages to a specific user if connected
const sendToUser = (io, userId, event, data) => {
  const socketId = userSocketMap.get(userId.toString());
  if (socketId) {
    io.to(socketId).emit(event, data);
  }
};

module.exports = {
  initSocket,
  sendToUser,
  userSocketMap,
};
