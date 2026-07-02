require('dotenv').config();
const http = require('http');
const app = require('./app');
const connectDB = require('./config/db');
const { initSocket } = require('./config/socket');

const PORT = process.env.PORT || 5000;

// Connect to Database
connectDB();

// Create HTTP Server
const server = http.createServer(app);

// Initialize Sockets
const io = initSocket(server);

// Share socket instance to express controllers
app.set('socketio', io);

// Start listening
server.listen(PORT, () => {
  console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
});
