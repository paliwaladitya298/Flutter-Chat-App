const User = require('../models/User');
const jwt = require('jsonwebtoken');

// Helper function to generate JWT
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'fallback_secret_key_12345', {
    expiresIn: '30d',
  });
};

/**
 * @desc    Register a new user
 * @route   POST /api/auth/register
 * @access  Public
 */
const registerUser = async (req, res, next) => {
  const { username, email, password, avatarUrl } = req.body;

  if (!username || !email || !password) {
    res.status(400);
    return next(new Error('Please fill all required fields'));
  }

  try {
    // Check if user already exists (by email or username)
    const emailExists = await User.findOne({ email });
    if (emailExists) {
      res.status(400);
      return next(new Error('Email already registered'));
    }

    const usernameExists = await User.findOne({ username });
    if (usernameExists) {
      res.status(400);
      return next(new Error('Username already taken'));
    }

    // Create the user
    const user = await User.create({
      username,
      email,
      password,
      avatarUrl: avatarUrl || '',
    });

    if (user) {
      res.status(201).json({
        _id: user._id,
        username: user.username,
        email: user.email,
        avatarUrl: user.avatarUrl,
        isOnline: user.isOnline,
        token: generateToken(user._id),
      });
    } else {
      res.status(400);
      return next(new Error('Invalid user data'));
    }
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Authenticate user and get token
 * @route   POST /api/auth/login
 * @access  Public
 */
const loginUser = async (req, res, next) => {
  const { emailOrUsername, password } = req.body;

  if (!emailOrUsername || !password) {
    res.status(400);
    return next(new Error('Please provide email/username and password'));
  }

  try {
    // Find user by email OR username
    const user = await User.findOne({
      $or: [
        { email: emailOrUsername.toLowerCase() },
        { username: emailOrUsername },
      ],
    });

    if (user && (await user.comparePassword(password))) {
      // Mark as online when logging in
      user.isOnline = true;
      await user.save();

      res.json({
        _id: user._id,
        username: user.username,
        email: user.email,
        avatarUrl: user.avatarUrl,
        isOnline: user.isOnline,
        token: generateToken(user._id),
      });
    } else {
      res.status(401);
      return next(new Error('Invalid email/username or password'));
    }
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get user profile (current user)
 * @route   GET /api/auth/me
 * @access  Private
 */
const getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);
    if (user) {
      res.json(user);
    } else {
      res.status(404);
      return next(new Error('User not found'));
    }
  } catch (error) {
    next(error);
  }
};

module.exports = {
  registerUser,
  loginUser,
  getMe,
};
