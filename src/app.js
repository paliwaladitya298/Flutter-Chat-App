const express = require('express');
const cors = require('cors');
const path = require('path');
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const chatRoutes = require('./routes/chatRoutes');
const messageRoutes = require('./routes/messageRoutes');
const { notFound, errorHandler } = require('./middleware/errorMiddleware');

const app = express();

// Apply global middlewares
app.use(cors({ origin: '*' }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve local static uploaded files
const publicDir = path.join(__dirname, 'public');
app.use('/uploads', express.static(path.join(publicDir, 'uploads')));

// Serve root visual feedback
app.get('/', (req, res) => {
  res.json({ message: 'Real-time Chat App Backend API is running...' });
});

// Register API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/messages', messageRoutes);

// Error Handling Middleware
app.use(notFound);
app.use(errorHandler);

module.exports = app;
