const User = require('../models/User');

/**
 * @desc    Search users by username or email
 * @route   GET /api/users
 * @access  Private
 */
const searchUsers = async (req, res, next) => {
  const searchQuery = req.query.search || req.query.query || '';

  try {
    const filter = searchQuery
      ? {
          $and: [
            {
              $or: [
                { username: { $regex: searchQuery, $options: 'i' } },
                { email: { $regex: searchQuery, $options: 'i' } },
              ],
            },
            { _id: { $ne: req.user._id } }, // Exclude current user from search
          ],
        }
      : { _id: { $ne: req.user._id } }; // If empty query, return all users except current

    const users = await User.find(filter).select('-password');
    res.json(users);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  searchUsers,
};
