
exports.authMiddleware = (req, res, next) => {
  const userId = req.headers['x-user'];
  
  if (!userId) {
    return res.status(401).json({ error: 'x-user header required' });
  }
  
  
  req.user = userId;
  
  next();
};